-- lua/mermaider/files.lua
-- File operation utilities for Mermaider

local M = {}
M.tempfiles = {}

local fn  = vim.fn
local api = vim.api

--- Path separator for current OS
local path_sep = package.config:sub(1, 1)

--- Generate a temporary file path for a buffer
--- @param config table: plugin configuration
--- @param bufnr number: buffer id
--- @return string: path for temporary file (without extension)
function M.get_temp_file_path(config, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local buf_name  = api.nvim_buf_get_name(bufnr)
  local file_name = fn.fnamemodify(buf_name, ":t:r")

  -- Ensure temp directory exists
  fn.mkdir(config.temp_dir, "p")

  -- Create full temporary file path
  local temp_path = config.temp_dir .. path_sep .. file_name .. "_" .. file_name

  return temp_path
end

--- Clean up temporary files for a buffer
--- @param temp_files table: table of temp file paths to clean
function M.cleanup_temp_files(temp_files)
  for _bufnr, temp_path in pairs(temp_files) do
    pcall(os.remove, temp_path .. ".png")
  end
end

return M
