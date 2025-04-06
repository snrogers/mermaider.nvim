-- lua/mermaider/types.lua
-- Type definitions for Mermaider plugin
-- Used for documentation and reference only (Lua is dynamically typed)

--[[
-- Configuration type
---@class MermaiderConfig
---@field mermaider_cmd string Command to render mermaid diagrams
---@field temp_dir string Directory for temporary files
---@field auto_render boolean Whether to auto-render on save
---@field auto_render_on_open boolean Whether to auto-render on file open
---@field use_split boolean Whether to use a split window for preview
---@field split_direction string "vertical" or "horizontal"
---@field split_width number Width of the split window
---@field theme string Mermaid theme ("dark", "light", etc.)
---@field background_color string Background color in hex format
---@field mmdc_options string Additional options for mermaid-cli
---@field external_viewer string|nil External viewer command
---@field kitty table Kitty terminal options

-- Kitty terminal options
---@class KittyOptions
---@field placement string Image placement method ("cursor" or "fixed")
---@field width string|number Width of displayed image ("auto" or number)
---@field height string|number Height of displayed image ("auto" or number)
---@field scale number Scale factor for image

-- Render status type
---@alias RenderStatus
---| "idle" # No rendering in progress
---| "rendering" # Rendering in progress
---| "success" # Rendering completed successfully
---| "error" # Rendering failed

-- File path type
---@alias FilePath string Path to a file

-- Command type
---@alias Command string Shell command to execute
]]

return {}
