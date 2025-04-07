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
function M.render_buffer(config, bufnr, callback)
  if not api.nvim_buf_is_valid(bufnr) then
    utils.safe_notify("Invalid buffer: " .. bufnr, vim.log.levels.ERROR)
    return
  end

  -- Set status to rendering
  status.set_status(bufnr, status.STATUS.RENDERING)

  -- Get temporary file paths
  local temp_path = files.get_temp_file_path(config, bufnr)
  local input_file = temp_path .. ".mmd"
  local output_file = temp_path

  -- Write buffer content to temp file
  local write_ok, write_err = files.write_buffer_to_temp_file(bufnr, input_file)
  if not write_ok then
    status.set_status(bufnr, status.STATUS.ERROR, "Failed to write temp file")
    utils.safe_notify("Failed to write temp file: " .. tostring(write_err), vim.log.levels.ERROR)
    if callback then callback(false, write_err) end
    return
  end

  -- Build the render command
  local cmd = commands.build_render_command(config, output_file)
  cmd = cmd:gsub("{{IN_FILE}}", input_file)

  -- Execute the render command
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

  -- Store the job handle
  active_jobs[bufnr] = commands.execute_async(cmd, nil, on_success, on_error)
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
