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
  assert(
    files.file_exists(image_path),
    "No rendered diagram found. Try running MermaiderRender first."
  )

  vim.schedule(function()
    local success = image_integration.render_inline(bufnr, image_path, config)
    assert(success, "Failed to render diagram inline")
  end)
end

return M
