-- lua/mermaider/commands.lua
local M = {}

local utils = require("mermaider.utils")
local files = require("mermaider.files")
local status = require("mermaider.status")


--- Execute a command asynchronously
--- @param config        table    Plugin configuration
--- @param stdin_content string   Content to pipe to stdin
--- @param callback      function Callback with (success, result) parameters
--- @param bufnr         number   Buffer id
--- @return vim.SystemObj
function M.execute_render_job(config, stdin_content, callback, bufnr)
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
    text = true, -- Return stdout/stderr as strings, not bytes
    stdin = stdin_content,
  }

  local on_success = function()
    status.set_status(bufnr, status.STATUS.SUCCESS)
    utils.safe_notify("Rendered diagram to " .. output_file .. ".png")
    callback(true, output_file .. ".png")
  end

  local on_error = function(error_output)
    status.set_status(bufnr, status.STATUS.ERROR, "Render failed")
    utils.safe_notify("Render failed: " .. error_output, vim.log.levels.ERROR)
    callback(false, error_output)
  end

  local job = vim.system(
    {"sh", "-c", cmd},
    job_opts,
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        on_success()
      else
        on_error(result.stderr)
      end
    end)
  )

  return job -- Can be used to kill the job with job:kill()
end

return M
