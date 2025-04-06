-- lua/mermaider/commands.lua
-- Command building and execution functions for Mermaider

local M = {}
local uv = vim.uv or vim.loop
local utils = require("mermaider.utils")

-- Build a mermaid render command with given options
-- @param config table: plugin configuration
-- @param input_file string: path to input mermaid file
-- @param output_file string: base path for output (extension will be added)
-- @return string: the complete command
function M.build_render_command(config, input_file, output_file)
  -- Start with base command
  local cmd = config.mermaider_cmd
    :gsub("{{IN_FILE}}", input_file)
    :gsub("{{OUT_FILE}}", output_file)

  -- Build options table
  local options = {}

  -- Add theme if specified
  if config.theme and config.theme ~= "" then
    table.insert(options, "--theme " .. config.theme)
  end

  -- Add background color if specified
  if config.background_color and config.background_color ~= "" then
    table.insert(options, "--backgroundColor " .. config.background_color)
  end

  -- Add additional options
  if config.mmdc_options and config.mmdc_options ~= "" then
    table.insert(options, config.mmdc_options)
  end

  -- Combine all options
  if #options > 0 then
    cmd = cmd .. " " .. table.concat(options, " ")
  end

  return cmd
end

-- Execute a command asynchronously with proper output handling
-- @param cmd string: command to execute
-- @param on_success function: callback for successful execution
-- @param on_error function: callback for failed execution
-- @return handle: the process handle
function M.execute_async(cmd, on_success, on_error)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local output = ""
  local error_output = ""

  utils.safe_notify("Executing: " .. cmd, vim.log.levels.DEBUG)

  local handle
  handle = uv.spawn("sh", {
    args = { "-c", cmd },
    stdio = { nil, stdout, stderr }
  }, function(code)
    stdout:close()
    stderr:close()
    handle:close()

    if code == 0 then
      if on_success then
        on_success(output)
      end
    else
      if on_error then
        on_error(error_output, cmd)
      end
    end
  end)

  -- Collect stdout
  stdout:read_start(function(err, data)
    if err then
      error_output = error_output .. "Stdout error: " .. tostring(err)
      return
    end
    if data then
      output = output .. data
    end
  end)

  -- Collect stderr
  stderr:read_start(function(err, data)
    if err then
      error_output = error_output .. "Stderr error: " .. tostring(err)
      return
    end
    if data then
      error_output = error_output .. data
    end
  end)

  return handle
end

return M
