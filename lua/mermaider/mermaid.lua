-- lua/mermaider/mermaid.lua
-- Core Mermaid diagram functionality with image.nvim

local M = {}

local api = vim.api
local files = require("mermaider.files")
local image_integration = require("mermaider.image_integration")
local ui = require("mermaider.ui")
local utils = require("mermaider.utils")

-- Preview a rendered mermaid diagram using image.nvim
-- @param bufnr number: buffer id
-- @param image_path string: path to the rendered image
-- @param config table: plugin configuration
function M.preview_diagram(bufnr, image_path, config)
  if not files.file_exists(image_path) then
    utils.safe_notify("No rendered diagram found. Try running MermaiderRender first.", vim.log.levels.ERROR)
    return
  end

  vim.schedule(function()
    if image_integration.render_inline(bufnr, image_path, config) then
      utils.safe_notify("Diagram rendered inline with image.nvim", vim.log.levels.INFO)
    else
      utils.safe_notify("Failed to render diagram inline", vim.log.levels.ERROR)
    end
  end)
end

return M
