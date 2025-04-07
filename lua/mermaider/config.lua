-- lua/mermaider/config.lua
-- Configuration management for Mermaider plugin with image.nvim

local M = {}
local fn = vim.fn

-- Default configuration
-- @class MermaiderConfig
M.defaults = {
  auto_render                  = true,
  mermaider_cmd                = 'bunx -y -p @mermaid-js/mermaid-cli mmdc -o {{OUT_FILE}}.png -s 3 -i -',
  temp_dir                     = fn.expand('$HOME/.cache/mermaider'),
  theme                        = "forest",
}

--- Validate configuration
---@param config MermaiderConfig
---@return MermaiderConfig
function M.validate(config)
  ---@class MermaiderConfig
  local result = vim.deepcopy(config)

  -- Ensure temp directory exists
  -- TODO: Move this to when we create the image render
  result.temp_dir = fn.expand(result.temp_dir)
  fn.mkdir(result.temp_dir, "p")

  return result
end

-- Process user configuration
function M.setup(user_config)
  local config = vim.tbl_deep_extend("force", M.defaults, user_config or {})
  M.validate(config)
  return config
end

return M
