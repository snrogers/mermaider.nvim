-- lua/mermaider/render.lua
-- Responsible for handling asynchronous rendering jobs for Mermaid diagrams

local M = {}
local commands = require("mermaider.commands")
local files    = require("mermaider.files")

-- Track running jobs by buffer number
local running_jobs = {}

-- Render a buffer with Mermaid content asynchronously
-- @param config table: plugin configuration
-- @param bufnr number: buffer id to render
-- @param callback function: optional callback after rendering completes
function M.render_buffer(config, bufnr, callback)
  -- Cancel any existing render job for this buffer
  M.cancel_render(bufnr)

  -- Get temporary file path
  local temp_path = files.get_temp_file_path(config, bufnr)

  -- Write buffer content to temp file
  local write_ok, write_err = files.write_buffer_to_temp_file(bufnr, temp_path)
  if not write_ok then
    if callback then
      callback(false, write_err)
    end
    return
  end

  -- Build render command
  local cmd = commands.build_render_command(config, temp_path, temp_path)

  -- Define callbacks for the async job
  local function on_success(output)
    -- Check if this is still the current job for this buffer
    if running_jobs[bufnr] and running_jobs[bufnr].is_current then
      running_jobs[bufnr] = nil
      if callback then
        callback(true, temp_path .. ".png")
      end
    end
  end

  local function on_error(error_output, failed_cmd)
    -- Check if this is still the current job for this buffer
    if running_jobs[bufnr] and running_jobs[bufnr].is_current then
      running_jobs[bufnr] = nil
      if callback then
        callback(false, error_output)
      end
    end
  end

  -- Start the async job
  local handle = commands.execute_async(cmd, on_success, on_error)

  -- Store job information
  running_jobs[bufnr] = {
    handle = handle,
    is_current = true
  }
end

-- Cancel an ongoing render job for a buffer
-- @param bufnr number: buffer id to cancel the render for
function M.cancel_render(bufnr)
  if running_jobs[bufnr] and running_jobs[bufnr].handle then
    -- Mark current job as no longer current
    running_jobs[bufnr].is_current = false

    -- Kill the job if possible
    pcall(function() running_jobs[bufnr].handle:kill() end)

    -- Remove from running jobs
    running_jobs[bufnr] = nil
  end
end

-- Cancel all running jobs
function M.cancel_all_jobs()
  for bufnr, _ in pairs(running_jobs) do
    M.cancel_render(bufnr)
  end
end

return M
