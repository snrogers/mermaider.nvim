-- lua/mermaider/render.lua
-- Rendering logic for Mermaider

local M = {}

local uv  = vim.uv
local api = vim.api

local files    = require("mermaider.files")
local commands = require("mermaider.commands")
local status   = require("mermaider.status")
local utils    = require("mermaider.utils")

-- Table to keep track of active render jobs
local active_jobs = {}

-- Render the buffer content as a Mermaid diagram
-- @param config table: plugin configuration
-- @param bufnr number: buffer id
-- @param callback function: callback with (success, result) parameters
function M.render_charts_in_buffer(config, bufnr, callback)
  assert(api.nvim_buf_is_valid(bufnr), "Invalid buffer: " .. bufnr)

  -- Set status to rendering
  status.set_status(bufnr, status.STATUS.RENDERING)

  -- Get temporary file path for output
  local output_file   = files.get_temp_file_path(config, bufnr)

  -- Build the render command
  local cmd = commands.build_render_command(config, output_file)

  -- Stdin-based approach
  local content = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

  local on_success = function()
    if files.file_exists(output_file .. ".png") then
      status.set_status(bufnr, status.STATUS.SUCCESS)
      utils.log_info("Rendered diagram to " .. output_file .. ".png")
      if callback then callback(true, output_file .. ".png") end
    else
      status.set_status(bufnr, status.STATUS.ERROR, "Output file not generated")
      utils.safe_notify("Output file not generated after rendering", vim.log.levels.ERROR)
      if callback then callback(false, "Output file not generated") end
    end
  end

  local on_error = function(error_output)
    status.set_status(bufnr, status.STATUS.ERROR, "Render failed")
    utils.safe_notify("Render failed: " .. error_output, vim.log.levels.ERROR)
    if callback then callback(false, error_output) end
  end

  active_jobs[bufnr] = commands.execute_async(cmd, content, on_success, on_error)
end

-- Cancel a specific render job
-- @param bufnr number: buffer id
function M.cancel_render(bufnr)
  local job = active_jobs[bufnr]
  if job and not job:is_closing() then
    job:close()
    active_jobs[bufnr] = nil
    status.set_status(bufnr, status.STATUS.IDLE)
    utils.log_info("Render cancelled for buffer " .. bufnr)
  end
end

-- Cancel all active render jobs
function M.cancel_all_jobs()
  for bufnr, job in pairs(active_jobs) do
    if job and not job:is_closing() then
      job:close()
      utils.log_info("Render job cancelled for buffer " .. bufnr)
    end
  end
  active_jobs = {}
end

return M
