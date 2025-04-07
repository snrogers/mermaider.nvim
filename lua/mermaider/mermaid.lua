-- lua/mermaider/mermaid.lua
-- Core Mermaid diagram functionality with image.nvim

local M = {}
local api = vim.api
local fn = vim.fn
local commands = require("mermaider.commands")
local files = require("mermaider.files")
local status = require("mermaider.status")
local utils = require("mermaider.utils")
local image_integration = require("mermaider.image_integration")
local ui = require("mermaider.ui")

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
    if config.inline_render then
      if image_integration.render_inline(bufnr, image_path, config) then
        utils.safe_notify("Diagram rendered inline with image.nvim", vim.log.levels.INFO)
      else
        utils.safe_notify("Failed to render diagram inline", vim.log.levels.ERROR)
      end
    else
      local split_direction = config.split_direction or "vertical"
      local split_width = config.split_width or 50
      local preview_buf, preview_win = ui.get_or_create_preview_window(split_direction, split_width)

      local win_width = api.nvim_win_get_width(preview_win)
      local win_height = api.nvim_win_get_height(preview_win)
      local image_width = win_width * 10
      local image_height = win_height * 20

      api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "" })

      local options = {
        buffer = preview_buf,
        window = preview_win,
        max_width = image_width,
        max_height = image_height,
        x = 0,
        y = 0,
      }

      image_integration.clear_image(preview_buf, preview_win)
      if image_integration.render_image(image_path, options) then
        utils.safe_notify("Diagram previewed in split window with image.nvim", vim.log.levels.INFO)
      else
        utils.safe_notify("Failed to preview diagram with image.nvim", vim.log.levels.ERROR)
      end
    end
  end)
end

return M
