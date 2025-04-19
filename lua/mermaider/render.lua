-- lua/mermaider/render.lua
-- Rendering logic for Mermaider

local M = {}

local api = vim.api

local files             = require("mermaider.files")
local image_integration = require("mermaider.image_integration")
local status            = require("mermaider.status")
local utils             = require("mermaider.utils")


--- Table to keep track of active render jobs
--- @type table<number, vim.SystemObj>
M._active_jobs = {}

--- Render the buffer content as a Mermaid diagram
--- TODO: Also handle split window rendering
--- @param config table: plugin configuration
--- @param bufnr number: buffer id
function M.render_mmd_buffer(config, bufnr)
  assert(api.nvim_buf_is_valid(bufnr), "Invalid buffer: " .. bufnr)

  status.set_status(bufnr, status.STATUS.RENDERING)

  --- On success, render the image inline
  local on_render_job_success = function(image_path)
    status.set_status(bufnr, status.STATUS.SUCCESS)
    utils.log_debug("Rendered diagram to " .. image_path)

    files.tempfiles[bufnr] = image_path
    vim.schedule(function()
      image_integration.render_inline(bufnr, image_path)
    end)
  end

  --- On error, set the status to error
  local on_render_job_error = function(err)
    status.set_status(bufnr, status.STATUS.ERROR, err)
  end

  M._active_jobs[bufnr]   = M._fork_render_job(
    config,
    bufnr,
    on_render_job_success,
    on_render_job_error
  )
end

--- Cancel a specific render job
--- @param bufnr number: buffer id
function M.cancel_render(bufnr)
  local job = M._active_jobs[bufnr]
  if job and not job:is_closing() then
    job:kill(9)
    M._active_jobs[bufnr] = nil
    status.set_status(bufnr, status.STATUS.IDLE)
    utils.log_info("Render cancelled for buffer " .. bufnr)
  end
end

--- Cancel all active render jobs
function M.cancel_all_jobs()
  for bufnr, job in pairs(M._active_jobs) do
    if job and not job:is_closing() then
      job:kill(9)
      utils.log_info("Render job cancelled for buffer " .. bufnr)
    end
  end
  M._active_jobs = {}
end

-- ----------------------------------------------------------------- --
-- Private API
-- ----------------------------------------------------------------- --

--- Execute a command asynchronously
--- @param config        table    Plugin configuration
--- @param bufnr         number   Buffer id
--- @param on_success    function Callback on success
--- @param on_error      function Callback on failure
--- @return vim.SystemObj
function M._fork_render_job(config, bufnr, on_success, on_error)
  local buffer_content = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local output_file = files.get_temp_file_path(config, bufnr)

  -- ----------------------------------------------------------------- --
  -- Build Command String
  -- ----------------------------------------------------------------- --
  local cmd = config.mermaider_cmd:gsub("{{OUT_FILE}}", output_file)
  if config.theme and config.theme ~= "" then
    cmd = cmd .. " --theme " .. config.theme
  end

  if config.background_color and config.background_color ~= "" then
    cmd = cmd .. " --backgroundColor " .. config.background_color
  end

  -- ----------------------------------------------------------------- --
  -- Execute Command
  -- ----------------------------------------------------------------- --
  local job_opts = {
    text  = true, -- Return stdout/stderr as strings, not bytes
    stdin = buffer_content,
  }

  local job = vim.system(
    {"sh", "-c", cmd},
    job_opts,
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        on_success(output_file .. ".png")
      else
        utils.log_error("Render failed: " ..result.stdout)
        utils.log_error("Render failed: " ..result.stderr)
        status.set_status(bufnr, status.STATUS.ERROR, "Render failed")
        on_error(result.stderr)
      end

      -- Cleanup
      files.tempfiles[bufnr] = nil
      M._active_jobs[bufnr]  = nil
    end)
  )

  return job -- Can be used to kill the job with job:kill()
end

-- ----------------------------------------------------------------- --
-- Module Export
-- ----------------------------------------------------------------- --

return M
