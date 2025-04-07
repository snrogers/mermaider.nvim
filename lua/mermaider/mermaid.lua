-- lua/mermaider/mermaid.lua
-- Core Mermaid diagram functionality with image.nvim

local M = {}

local api = vim.api
local files = require("mermaider.files")
local image_integration = require("mermaider.image_integration")
local utils = require("mermaider.utils")

--- Preview a rendered mermaid diagram using image.nvim
--- @param bufnr number: buffer id
--- @param image_path string: path to the rendered image
--- @param config table: plugin configuration
function M.preview_diagram(bufnr, image_path, config)
  if not files.file_exists(image_path) then
    utils.log_error("No rendered diagram found at: " .. image_path)
    return
  end
  utils.log_debug("Scheduling preview for buffer " .. bufnr .. " with image " .. image_path)
  vim.schedule(function()
    utils.log_debug("Inside vim.schedule for preview")
    local success = image_integration.render_inline(bufnr, image_path, config)
    if not success then
      utils.log_error("Failed to render diagram inline")
    end
  end)
end

return M
