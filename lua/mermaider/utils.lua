-- lua/mermaider/utils.lua
-- Utility functions for Mermaider

local M = {}
local api = vim.api

-- Log levels
M.LOG_LEVELS = {
  DEBUG = 0,
  INFO  = 1,
  WARN  = 2,
  ERROR = 3
}

-- Plugin name for logging
local PLUGIN_NAME = "Mermaider"

-- Global debug mode flag (set to true to enable verbose debugging)
M.debug_mode = true

--- Safe notification function that uses vim.schedule to avoid fast event context errors
--- @param msg string: the message to display
--- @param level number|nil: the message level (default: INFO)
function M.safe_notify(msg, level)
  level = level or vim.log.levels.INFO

  vim.schedule(function()
    vim.notify(msg, level, { title = PLUGIN_NAME })
  end)
end

--- Debug log function
--- @param msg string: debug message
function M.log_debug(msg)
  M.safe_notify("[DEBUG] " .. msg, vim.log.levels.DEBUG)
end

--- Error log function
--- @param msg string: error message
function M.log_error(msg)
  M.safe_notify("[ERROR] " .. msg, vim.log.levels.DEBUG)
end


--- Info log function
--- @param msg string: info message
function M.log_info(msg)
    M.safe_notify("[INFO] " .. msg, vim.log.levels.INFO)
end

--- Check if a command is available in the system
--- @param cmd string: command to check
--- @return boolean: true if command exists
function M.command_exists(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  handle:close()

  return result and result:len() > 0
end

--- Check if a program is installed
--- @param program string: program name
--- @return boolean: true if installed
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

--- Create a throttled function that only executes after a delay
--- @param func function: the function to throttle
--- @param delay number: delay in milliseconds
--- @return function: throttled function
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

return M
