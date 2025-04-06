-- lua/mermaider/files.lua
-- File operation utilities for Mermaider

local M = {}
local fn = vim.fn
local api = vim.api
local utils = require("mermaider.utils")

-- Path separator for current OS
local path_sep = package.config:sub(1, 1)

-- Generate a temporary file path for a buffer
-- @param config table: plugin configuration
-- @param bufnr number: buffer id
-- @return string: path for temporary file (without extension)
function M.get_temp_file_path(config, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local buf_name = api.nvim_buf_get_name(bufnr)
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

-- Write buffer content to a temporary file
-- @param bufnr number: buffer id
-- @param temp_path string: path to write the file
-- @return boolean, string: success flag and error message if any
function M.write_buffer_to_temp_file(bufnr, temp_path)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local ok, err = pcall(function()
    local file = io.open(temp_path, "w")
    if not file then
      error("Could not open file for writing: " .. temp_path)
    end

    file:write(table.concat(lines, "\n"))
    file:close()
  end)

  return ok, err
end

-- Check if a file exists and is readable
-- @param path string: file path to check
-- @return boolean: true if file exists and is readable
function M.file_exists(path)
  return fn.filereadable(path) == 1
end

-- Clean up temporary files for a buffer
-- @param temp_files table: table of temp file paths to clean
function M.cleanup_temp_files(temp_files)
  for bufnr, temp_path in pairs(temp_files) do
    -- Try to remove the base file
    pcall(os.remove, temp_path)

    -- Try to remove common extensions
    pcall(os.remove, temp_path .. ".png")
    pcall(os.remove, temp_path .. ".svg")
    pcall(os.remove, temp_path .. ".pdf")
  end
end

return M
