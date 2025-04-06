-- lua/mermaider/image_integration.lua
-- Image rendering with image.nvim

local M = {}
local utils = require("mermaider.utils")

M.image_objects = {} -- Buffer -> image object mapping

function M.is_available()
  local has_image_nvim, _ = pcall(require, "image")
  return has_image_nvim
end

function M.setup(config)
  if not M.is_available() then
    utils.log_error("image.nvim not available during setup")
    return false
  end
  utils.log_info("image.nvim integration enabled")
  return true
end

function M.render_image(image_path, options)
  if not M.is_available() then
    utils.log_error("image.nvim not available for rendering")
    return false
  end

  local image = require("image")
  options = options or {}

  if not vim.fn.filereadable(image_path) == 1 then
    utils.log_error("Image file not found: " .. image_path)
    return false
  end

  local display_options = {
    window = options.window or vim.api.nvim_get_current_win(),
    buffer = options.buffer or vim.api.nvim_get_current_buf(),
    max_width = options.max_width,
    max_height = options.max_height,
    row = options.row,
    col = options.col,
  }

  local buf = display_options.buffer
  local win = display_options.window
  local img = M.image_objects[buf]

  utils.log_debug("Rendering image for buffer " .. buf .. " in window " .. win)
  utils.log_debug("Image path: " .. image_path)

  local success, err
  if img then
    -- Check if the window has changed
    local current_win = img.window -- Assuming image.nvim stores the window ID (check API if needed)
    if current_win and current_win ~= win then
      utils.log_debug("Window changed for buffer " .. buf .. ". Clearing old image.")
      pcall(function() img:clear() end)
      img = nil
      M.image_objects[buf] = nil
    end
  end

  if img then
    -- Update existing image
    utils.log_debug("Reusing existing image object for buffer " .. buf)
    success, err = pcall(function()
      img.path = image_path -- Update path if needed
      img:render(display_options) -- Re-render with new geometry
    end)
  else
    -- Create new image
    utils.log_debug("Creating new image object for buffer " .. buf)
    success, err = pcall(function()
      img = image.from_file(image_path, display_options)
      img:render()
      M.image_objects[buf] = img
    end)
  end

  if not success then
    utils.log_error("Failed to render image: " .. tostring(err))
    return false
  end

  utils.log_info("Image rendered successfully with image.nvim")
  return true
end

function M.clear_images()
  if not M.is_available() then
    return false
  end

  local image = require("image")
  local success, err = pcall(function()
    for buf, img in pairs(M.image_objects) do
      img:clear()
      -- If the buffer is a preview buffer and not displayed, delete it
      local success, is_preview = pcall(vim.api.nvim_buf_get_var, buf, "mermaider_preview")
      if success and is_preview and vim.fn.bufwinid(buf) == -1 then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    M.image_objects = {}
    image.clear() -- Clear any untracked images
  end)

  if not success then
    utils.log_error("Failed to clear images: " .. tostring(err))
    return false
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local success, is_preview = pcall(vim.api.nvim_buf_get_var, buf, "mermaider_preview")
    if success and is_preview then
      vim.api.nvim_win_close(win, true)
    end
  end

  utils.log_debug("All images cleared")
  return true
end

function M.clear_image(buffer, window)
  if not M.is_available() then
    return false
  end

  local image = require("image")
  local success, err = pcall(function()
    -- Clear images associated with this buffer/window
    image.clear({ buffer = buffer, window = window })
  end)
  if not success then
    utils.log_error("Failed to clear image: " .. tostring(err))
    return false
  end
  utils.log_debug("Image cleared for buffer " .. buffer .. " and window " .. window)
  return true
end

return M
