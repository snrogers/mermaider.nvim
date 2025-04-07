-- lua/mermaider/commands.lua
-- Command building and execution functions for Mermaider

local M = {}
local uv = vim.uv or vim.loop
local utils = require("mermaider.utils")

-- Build a mermaid render command with given options
-- @param config table: plugin configuration
-- @param output_file string: base path for output (extension will be added)
-- @return string: the complete command
function M.build_render_command(config, output_file)
  local cmd = config.mermaider_cmd:gsub("{{OUT_FILE}}", output_file)

  local options = {}
  if config.theme and config.theme ~= "" then
    table.insert(options, "--theme " .. config.theme)
  end
  if config.background_color and config.background_color ~= "" then
    table.insert(options, "--backgroundColor " .. config.background_color)
  end
  if config.mmdc_options and config.mmdc_options ~= "" then
    table.insert(options, config.mmdc_options)
  end
  if #options > 0 then
    cmd = cmd .. " " .. table.concat(options, " ")
  end

  return cmd
end

-- Execute a command asynchronously with proper output handling
-- @param cmd string: command to execute
-- @param stdin_content string: content to pipe to stdin
-- @param on_success function: callback for successful execution
-- @param on_error function: callback for failed execution
-- @return handle: the process handle
function M.execute_async(cmd, stdin_content, on_success, on_error)
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local output = ""
  local error_output = ""

  local handle
  handle = uv.spawn("sh", {
    args = { "-c", cmd },
    stdio = { stdin, stdout, stderr }
  }, function(code)
    -- Only close handles if they are not already closed
    if stdout:is_closing() == false then stdout:close() end
    if stderr:is_closing() == false then stderr:close() end
    if stdin:is_closing() == false then stdin:close() end
    if handle:is_closing() == false then handle:close() end

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

  if not handle then
    utils.safe_notify("Failed to spawn process for command: " .. cmd, vim.log.levels.ERROR)
    if stdin then stdin:close() end
    if stdout then stdout:close() end
    if stderr then stderr:close() end
    return nil
  end

  if stdin_content then
    stdin:write(stdin_content, function(err)
      if err then
        error_output = error_output .. "Stdin write error: " .. tostring(err)
      end
      if stdin:is_closing() == false then stdin:close() end
    end)
  else
    if stdin:is_closing() == false then stdin:close() end
  end

  stdout:read_start(function(err, data)
    if err then
      error_output = error_output .. "Stdout error: " .. tostring(err)
      return
    end
    if data then
      output = output .. data
    end
  end)

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
