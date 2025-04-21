-- lua/mermaider/config.lua
-- Configuration management for Mermaider plugin with image.nvim

local M = {}
local fn = vim.fn


--- Default configuration
--- @class MermaiderConfig
M.config = {
  mermaider_cmd                = 'mmdc -o {{OUT_FILE}}.png -s 10 -i -',
  temp_dir                     = fn.expand('$HOME/.cache/mermaider'),
  auto_render                  = true,
  theme                        = "forest",
  background_color             = "#1e1e2e",
  max_width_window_percentage  = 80,
  max_height_window_percentage = 80,
}

-- Validate configuration
--- @param config MermaiderConfig
function M.validate(config)
  ---@class MermaiderConfig
  local result = vim.deepcopy(config)
  result.temp_dir = fn.expand(result.temp_dir)
  fn.mkdir(result.temp_dir, "p")

  if result.max_width_window_percentage and (type(result.max_width_window_percentage) ~= "number" or
    result.max_width_window_percentage <= 0 or result.max_width_window_percentage > 100) then
    vim.notify("[Mermaider] Invalid max_width_window_percentage, using default 80", vim.log.levels.WARN)
    result.max_width_window_percentage = 80
  end

  if result.max_height_window_percentage and (type(result.max_height_window_percentage) ~= "number" or
    result.max_height_window_percentage <= 0 or result.max_height_window_percentage > 100) then
    vim.notify("[Mermaider] Invalid max_height_window_percentage, using default 80", vim.log.levels.WARN)
    result.max_height_window_percentage = 80
  end

  return result
end

-- Process user configuration
function M.setup(user_config)
  vim.tbl_deep_extend("force", M.config, user_config or {})
  M.validate(M.config)
  return M.config
end

return M
