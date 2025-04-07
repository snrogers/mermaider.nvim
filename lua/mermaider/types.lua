-- lua/mermaider/types.lua
-- Type definitions for Mermaider plugin
-- Used for documentation and reference only (Lua is dynamically typed)


--[[
-- Configuration type
---@class MermaiderConfig
---@field mermaider_cmd string Command to render mermaid diagrams
---@field temp_dir string Directory for temporary files
---@field auto_render boolean Whether to auto-render on save
---@field theme string Mermaid theme ("dark", "light", etc.)
---@field background_color string Background color in hex format


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
