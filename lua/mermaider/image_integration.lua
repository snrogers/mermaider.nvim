-- lua/mermaider/image_integration.lua
-- Image rendering with image.nvim

local M = {}

local api = vim.api
local image = require("image")

local utils = require("mermaider.utils")

--- @type table<number, image.Image>
M.image_objects = {} -- Buffer -> image object mapping

-- ----------------------------------------------------------------- --
-- Public API
-- ----------------------------------------------------------------- --
function M.clear_images()
  image.clear()
  utils.log_debug("All images cleared")
  return true
end

function M.clear_image(buffer, window)
  local success, err = pcall(function()
    image.clear({ buffer = buffer, window = window })
    if M.image_objects[buffer] then
      M.image_objects[buffer] = nil
    end
  end)
  if not success then
    utils.log_error("Failed to clear image: " .. tostring(err))
    return false
  end
  utils.log_debug("Image cleared for buffer " .. buffer .. " and window " .. window)
  return true
end

--- Render an image inline in the current window
--- @param code_bufnr number: buffer id of the code buffer
--- @param image_path string: path to the rendered image
--- @return boolean: true if successful, false otherwise
function M.render_inline(code_bufnr, image_path)
  local current_win = api.nvim_get_current_win()

  local line_count = api.nvim_buf_line_count(code_bufnr)

  local row = line_count
  local col = 0

  local win_width  = api.nvim_win_get_width(current_win)
  local win_height = api.nvim_win_get_height(current_win)

  utils.log_debug("current_win: " .. current_win)
  utils.log_debug("Window width: " .. win_width)
  utils.log_debug("Window height: " .. win_height)

  ---@type ImageOptions
  local render_image_options = {
    buffer = code_bufnr,
    x = col,
    y = row,
    width  = win_width,
    height = win_height,
    with_virtual_padding = true,
    inline = true,
  }

  local success = M.render_image(image_path, render_image_options)
  if success then
    utils.log_info("Mermaid diagram rendered inline with image.nvim")
  else
    utils.log_error("Failed to render inline Mermaid diagram")
  end
  return success
end


-- ----------------------------------------------------------------- --
-- Private API
-- ----------------------------------------------------------------- --

---@class ImageOptions
---@field buffer number: buffer id
---@field width number: width of the image
---@field height number: height of the image
---@field x number: x position of the image
---@field y number: y position of the image
---@field with_virtual_padding boolean: whether to use virtual padding
---@field inline boolean: whether to render inline

---@param image_path string: path to the image file
---@param options ImageOptions: options for rendering the image
function M.render_image(image_path, options)
  assert(
    vim.fn.filereadable(image_path) == 1,
    "Image file not readable: " .. image_path
  )

  local buf = options.buffer
  local img = M.image_objects[buf]

  utils.log_debug("Rendering image for buffer " .. buf)
  utils.log_debug("Image path: " .. image_path)

  local success, err

  if img then
    -- Update existing image
    utils.log_debug("Reusing existing image object for buffer " .. buf)
    success, err = pcall(function()
      img.path = image_path -- TODO: I don't think this is necessary
      img:render(options)
    end)
  else
    -- Create new image
    utils.log_debug("Creating new image object for buffer " .. buf)
    success, err = pcall(function()
      img = image.from_file(image_path, options)
      img:render(options)
      M.image_objects[buf] = img
    end)
  end

  if not success then
    utils.log_error("Failed to render image: " .. tostring(err))
    return false
  else
    utils.log_info("Image rendered successfully with image.nvim")
  end

  utils.log_info("Image rendered successfully with image.nvim")
  return true
end

return M
