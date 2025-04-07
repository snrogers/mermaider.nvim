-- lua/mermaider/config.lua
-- Configuration management for Mermaider plugin with image.nvim

local M = {}
local fn = vim.fn

-- Default configuration
M.defaults = {
  mermaider_cmd                = 'npx -y -p @mermaid-js/mermaid-cli mmdc -o {{OUT_FILE}}.png -s 3 -i -',
  temp_dir                     = fn.expand('$HOME/.cache/mermaider'),
  auto_render                  = true,
  auto_render_on_open          = true,
  auto_preview                 = true,
  theme                        = "forest",
  background_color             = "#1e1e2e",
  mmdc_options                 = "",
  max_width_window_percentage  = 80,
  max_height_window_percentage = 80,

  -- Render settings
  inline_render                = true,       -- Use inline rendering instead of split window

  -- Split window settings (used when inline_render is false)
  use_split                    = true,       -- Use a split window to show diagram
  split_direction              = "vertical", -- "vertical" or "horizontal"
  split_width                  = 50,         -- Width of the split (if vertical)
}

-- Validate configuration
function M.validate(config)
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
  local config = vim.tbl_deep_extend("force", M.defaults, user_config or {})
  return M.validate(config)
end

return M
