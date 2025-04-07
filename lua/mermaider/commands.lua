-- lua/mermaider/commands.lua
local M = {}
local utils = require("mermaider.utils")


-- Build a mermaid render command with given options
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
function M.execute_async(cmd, stdin_content, on_success, on_error)
  local opts = {
    text = true, -- Return stdout/stderr as strings, not bytes
    stdin = stdin_content,
  }

  local job = vim.system(
    {"sh", "-c", cmd},
    opts,
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        on_success(result.stdout)
      else
        on_error(result.stderr, cmd)
      end
    end)
  )

  return job -- Can be used to kill the job with job:kill()
end

return M
