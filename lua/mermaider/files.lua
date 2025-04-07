-- lua/mermaider/files.lua
-- File operation utilities for Mermaider

local M = {}
local fn  = vim.fn
local api = vim.api

-- Path separator for current OS
local path_sep = package.config:sub(1, 1)

--- Generate a temporary file path for a buffer
--- @param config table: plugin configuration
--- @param bufnr number: buffer id
--- @return string: path for temporary file (without extension)
function M.get_temp_file_path(config, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local buf_name  = api.nvim_buf_get_name(bufnr)
  local file_name = fn.fnamemodify(buf_name, ":t:r")

  -- Generate a hash based on the absolute path
  local abs_path = fn.fnamemodify(buf_name, ":p")
  local hash_sum = 0

  -- Convert the absolute path to a stable hash
  for i = 1, #abs_path do
    hash_sum = hash_sum + string.byte(abs_path, i)
  end
  local hash_str = tostring(hash_sum)

  -- Ensure temp directory exists
  fn.mkdir(config.temp_dir, "p")

  -- Create full temporary file path
  local temp_path = config.temp_dir .. path_sep .. file_name .. "_" .. hash_str

  return temp_path
end

--- Check if a file exists and is readable
--- @param path string: file path to check
--- @return boolean: true if file exists and is readable
function M.file_exists(path)
  return fn.filereadable(path) == 1
end

--- Clean up temporary files for a buffer
--- @param temp_files table: table of temp file paths to clean
function M.cleanup_temp_files(temp_files)
  for bufnr, temp_path in pairs(temp_files) do
    pcall(os.remove, temp_path .. ".png")
  end
end

return M
