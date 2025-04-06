-- lua/mermaider/ui.lua
-- UI helpers for Mermaider plugin

local M = {}
local api = vim.api
local fn = vim.fn
local utils = require("mermaider.utils")

-- Constants
local PREVIEW_BUF_VAR = "_mermaider_preview"
local PREVIEW_BUF_NAME = "MermaidPreview"

-- Get or create a preview window for displaying rendered diagrams
-- @param split_direction string: "vertical" or "horizontal"
-- @param split_width number: width of the split (if vertical)
-- @return buffer, window: buffer id and window id
function M.get_or_create_preview_window(split_direction, split_width)
  split_direction = split_direction or "vertical"
  split_width = split_width or 50
  local current_win = vim.api.nvim_get_current_win()

  -- Find an existing preview buffer by variable
  local preview_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local success, is_preview = pcall(vim.api.nvim_buf_get_var, buf, "mermaider_preview")
    if success and is_preview then
      preview_buf = buf
      break
    end
  end

  local buf, win
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    -- Reuse the buffer; find or create a window for it
    local win_id = vim.fn.bufwinid(preview_buf)
    if win_id ~= -1 then
      win = win_id
    else
      local split_cmd = split_direction == "vertical" and "vsplit" or "split"
      -- Apply split width for vertical splits, or height for horizontal splits
      if split_direction == "vertical" then
        vim.cmd(split_width .. split_cmd)
      else
        vim.cmd(split_cmd)
        vim.api.nvim_win_set_height(0, split_width) -- Use split_width as height for horizontal split
      end
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, preview_buf)
    end
    buf = preview_buf
  else
    -- Create a new split and buffer
    local split_cmd = split_direction == "vertical" and "vsplit" or "split"
    if split_direction == "vertical" then
      vim.cmd(split_width .. split_cmd)
    else
      vim.cmd(split_cmd)
      vim.api.nvim_win_set_height(0, split_width)
    end
    win = vim.api.nvim_get_current_win()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_var(buf, "mermaider_preview", true) -- Mark as preview buffer
    vim.api.nvim_buf_set_name(buf, "MermaidPreview") -- Optional, for clarity
  end

  vim.api.nvim_set_current_win(current_win) -- Restore focus
  return buf, win
end

-- Display text content in a preview buffer
-- @param buf number: buffer id
-- @param lines table: lines to display
-- @param modifiable boolean: whether the buffer should be modifiable after
function M.set_preview_content(buf, lines, modifiable)
  modifiable = modifiable or false

  if not api.nvim_buf_is_valid(buf) then
    utils.safe_notify("Invalid buffer when setting preview content", vim.log.levels.ERROR)
    return
  end

  api.nvim_buf_set_option(buf, "modifiable", true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_buf_set_option(buf, "modifiable", modifiable)
end

-- Get the appropriate external viewer command for the current OS
-- @param image_path string: path to the image file
-- @param external_viewer string|nil: custom viewer command (optional)
-- @return string: the command to open the image
function M.get_external_viewer_command(image_path, external_viewer)
  if external_viewer then
    return external_viewer .. " " .. fn.shellescape(image_path)
  end

  -- Use system default based on OS
  if fn.has("mac") == 1 then
    return "open " .. fn.shellescape(image_path)
  elseif fn.has("unix") == 1 then
    return "xdg-open " .. fn.shellescape(image_path)
  elseif fn.has("win32") == 1 or fn.has("win64") == 1 then
    return "start " .. fn.shellescape(image_path)
  else
    error("Unknown OS, cannot determine default image viewer")
  end
end

return M
