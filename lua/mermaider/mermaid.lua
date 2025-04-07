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

-- Render the current buffer as a mermaid diagram
-- @param config table: plugin configuration
-- @param bufnr number: buffer id to render
-- @param callback function: optional callback after rendering completes
function M.render_buffer(config, bufnr, callback)
  bufnr = bufnr or api.nvim_get_current_buf()
  local buf_name = api.nvim_buf_get_name(bufnr)
  local file_type = fn.fnamemodify(buf_name, ":e")

  if file_type ~= "mmd" and file_type ~= "mermaid" then
    utils.safe_notify("Not a mermaid file", vim.log.levels.DEBUG)
    return
  end

  status.set_status(bufnr, status.STATUS.RENDERING, "Processing")
  local temp_input = files.get_temp_file_path(config, bufnr)

  local write_ok, write_err = files.write_buffer_to_temp_file(bufnr, temp_input)
  if not write_ok then
    status.set_status(bufnr, status.STATUS.ERROR, "File write failed")
    utils.safe_notify("Failed to write temp file: " .. write_err, vim.log.levels.ERROR)
    return
  end

  local cmd = commands.build_render_command(config, temp_input, temp_input)

  local function on_success(output)
    status.set_status(bufnr, status.STATUS.SUCCESS, "Rendered")
    utils.safe_notify("Mermaid diagram rendered successfully", vim.log.levels.INFO)
    if callback then
      callback(true, temp_input .. ".png")
    end
  end

  local function on_error(error_output, failed_cmd)
    status.set_status(bufnr, status.STATUS.ERROR, "Failed")
    utils.safe_notify("Failed to render mermaid diagram: " .. error_output, vim.log.levels.ERROR)
    if callback then
      callback(false, error_output)
    end
  end

  utils.safe_notify("Rendering mermaid diagram...", vim.log.levels.INFO)
  commands.execute_async(cmd, on_success, on_error)
end

return M
