-- lua/mermaider/utils.lua
-- Utility functions for Mermaider

local M = {}
local api = vim.api

-- Log levels
M.LOG_LEVELS = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

-- Plugin name for logging
local PLUGIN_NAME = "Mermaider"

-- Global debug mode flag (set to true to enable verbose debugging)
M.debug_mode = true

-- Safe notification function that uses vim.schedule to avoid fast event context errors
-- @param msg string: the message to display
-- @param level number|nil: the message level (default: INFO)
function M.safe_notify(msg, level)
  level = level or vim.log.levels.INFO

  vim.schedule(function()
    vim.notify(msg, level, { title = PLUGIN_NAME })
  end)
end

-- Debug log function
-- @param msg string: debug message
function M.log_debug(msg)
    M.safe_notify("[DEBUG] " .. msg, vim.log.levels.DEBUG)
end

-- Info log function
-- @param msg string: info message
function M.log_info(msg)
    M.safe_notify("[INFO] " .. msg, vim.log.levels.INFO)
end

-- Log a message to Neovim command line
-- @param msg string: the message to display
-- @param level string|nil: log level (default: "INFO")
function M.log(msg, level)
  level = level or "INFO"

  local level_str = level
  local hl_group = "Normal"

  -- Set highlight group based on level
  if level == "ERROR" then
    hl_group = "ErrorMsg"
  elseif level == "WARN" then
    hl_group = "WarningMsg"
  elseif level == "DEBUG" then
    hl_group = "Comment"
  end

  -- Ensure we're in a safe context
  vim.schedule(function()
    api.nvim_echo({{"[" .. PLUGIN_NAME .. "] " .. level_str .. ": " .. msg, hl_group}}, false, {})
  end)
end

-- Log to a debug buffer
-- @param msg string: message to log
-- @param level number: message level
function M.log_to_buffer(msg, level)
  -- Only create debug buffer if needed
  if not M._debug_buf or not api.nvim_buf_is_valid(M._debug_buf) then
    M._debug_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(M._debug_buf, "MermaiderDebug")
    api.nvim_buf_set_option(M._debug_buf, "buftype", "nofile")
    api.nvim_buf_set_option(M._debug_buf, "bufhidden", "hide")
  end

  -- Add timestamp to message
  local timestamp = os.date("%H:%M:%S")
  local level_name = "INFO"
  if level == vim.log.levels.DEBUG then level_name = "DEBUG"
  elseif level == vim.log.levels.WARN then level_name = "WARN"
  elseif level == vim.log.levels.ERROR then level_name = "ERROR" end

  local full_msg = string.format("[%s] [%s] %s", timestamp, level_name, msg)

  -- Append to the buffer
  local line_count = api.nvim_buf_line_count(M._debug_buf)
  api.nvim_buf_set_lines(M._debug_buf, line_count, line_count, false, {full_msg})
end

-- Open debug buffer in a new split
function M.open_debug_buffer()
  if not M._debug_buf or not api.nvim_buf_is_valid(M._debug_buf) then
    M._debug_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(M._debug_buf, "MermaiderDebug")
    api.nvim_buf_set_option(M._debug_buf, "buftype", "nofile")
    api.nvim_buf_set_option(M._debug_buf, "bufhidden", "hide")
    api.nvim_buf_set_lines(M._debug_buf, 0, 0, false, {"Mermaider Debug Log", "=================="})
  end

  vim.cmd("split")
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, M._debug_buf)
  api.nvim_win_set_height(win, 15) -- Set height of debug window

  return M._debug_buf
end

-- Check if a command is available in the system
-- @param cmd string: command to check
-- @return boolean: true if command exists
function M.command_exists(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  handle:close()

  return result and result:len() > 0
end

-- Check if a program is installed
-- @param program string: program name
-- @return boolean: true if installed
function M.is_program_installed(program)
  -- First try command -v (POSIX)
  if M.command_exists(program) then
    return true
  end

  -- For Windows systems, try where
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local handle = io.popen("where " .. program .. " 2>nul")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result and result:len() > 0 then
        return true
      end
    end
  end

  return false
end

-- Create a throttled function that only executes after a delay
-- @param func function: the function to throttle
-- @param delay number: delay in milliseconds
-- @return function: throttled function
function M.throttle(func, delay)
  local timer = nil
  local last_exec = 0

  return function(...)
    local args = {...}
    local now = vim.loop.now()
    local ms_since_last = now - last_exec

    -- If timer already exists, cancel it
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end

    -- If enough time has passed, execute immediately
    if ms_since_last > delay then
      last_exec = now
      func(unpack(args))
      return
    end

    -- Otherwise schedule for later
    timer = vim.loop.new_timer()
    timer:start(delay - ms_since_last, 0, vim.schedule_wrap(function()
      last_exec = vim.loop.now()
      func(unpack(args))
      timer:stop()
      timer:close()
      timer = nil
    end))
  end
end

-- Call a function safely with pcall and error logging
-- @param func function: function to call
-- @param ... any: arguments to pass to func
-- @return any: result of the function if successful, or nil on error
function M.safe_call(func, ...)
  local ok, result = pcall(func, ...)
  if not ok then
    M.safe_notify("Error: " .. tostring(result), vim.log.levels.ERROR)
    return nil
  end
  return result
end

-- Add a debug command to view logs
function M.setup_debug_commands()
  vim.api.nvim_create_user_command("MermaiderDebug", function()
    M.open_debug_buffer()
  end, {
    desc = "Open Mermaider debug log"
  })

  vim.api.nvim_create_user_command("MermaiderToggleDebug", function()
    M.debug_mode = not M.debug_mode
    M.safe_notify("Debug mode " .. (M.debug_mode and "enabled" or "disabled"), vim.log.levels.INFO)
  end, {
    desc = "Toggle Mermaider debug mode"
  })
end

return M
