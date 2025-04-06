-- lua/mermaider/init.lua
-- Main entry point for Mermaider plugin, now focused on image.nvim

local M = {}
local api = vim.api
local fn = vim.fn

-- Import modules
local utils = require("mermaider.utils")
local mermaid = require("mermaider.mermaid")
local files = require("mermaider.files")
local config_module = require("mermaider.config")
local image_integration = require("mermaider.image_integration")

-- Configuration will be populated in setup()
M.config = {}

-- Tracking variables
M.tempfiles = {}
M.render_jobs = {}

-- Setup function
-- @param opts table: user configuration options
function M.setup(opts)
  M.config = config_module.setup(opts)

  M.check_dependencies()

  -- Initialize image.nvim integration (now mandatory)
  image_integration.setup(M.config)

  -- Create user commands
  api.nvim_create_user_command("MermaiderRender", function()
    M.render_current_buffer()
  end, { desc = "Render the current mermaid diagram" })

  api.nvim_create_user_command("MermaiderPreview", function()
    local bufnr = api.nvim_get_current_buf()
    local image_path = files.get_temp_file_path(M.config, bufnr) .. ".png"
    mermaid.preview_diagram(bufnr, image_path, M.config)
  end, { desc = "Preview the current mermaid diagram" })

  M.setup_autocmds()

  utils.safe_notify("Mermaider plugin loaded with image.nvim", vim.log.levels.INFO)
end

-- Check if required dependencies are available
function M.check_dependencies()
  -- Check if npx is available
  if not utils.is_program_installed("npx") then
    utils.safe_notify(
      "npx command not found. Please install Node.js and npm.",
      vim.log.levels.WARN
    )
  end

  -- Check for image.nvim (now required)
  if not image_integration.is_available() then
    utils.safe_notify(
      "image.nvim not available. Please ensure it's installed and configured.",
      vim.log.levels.ERROR
    )
  end
end

-- Set up autocommands
function M.setup_autocmds()
  local augroup = api.nvim_create_augroup("Mermaider", { clear = true })

  -- Auto render on save
  if M.config.auto_render then
    api.nvim_create_autocmd({ "BufWritePost" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        M.render_current_buffer()
      end,
    })
  end

  -- Auto render on open
  if M.config.auto_render_on_open then
    api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        M.render_current_buffer()
      end,
    })
  end

  -- Clean up temp files and images on exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      files.cleanup_temp_files(M.tempfiles)
      image_integration.clear_images()
    end,
  })

  -- Re-render the image on window resize
  api.nvim_create_autocmd({ "WinResized" }, {
    group = augroup,
    callback = function()
      -- Check if the resized window is the preview window
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local success, is_preview = pcall(vim.api.nvim_buf_get_var, buf, "mermaider_preview")
        if success and is_preview then
          -- Re-render the image in the preview window
          -- You might need to store the image_path and config somewhere
          -- For simplicity, you can trigger a full re-render
          M.render_current_buffer()
        end
      end
    end,
  })
end

-- Render the current buffer
function M.render_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  local temp_path = files.get_temp_file_path(M.config, bufnr)
  M.tempfiles[bufnr] = temp_path

  if M.render_jobs[bufnr] and M.render_jobs[bufnr].kill then
    pcall(function() M.render_jobs[bufnr]:kill() end)
    M.render_jobs[bufnr] = nil
  end

  local on_complete = function(success, result)
    M.render_jobs[bufnr] = nil
    if success and M.config.auto_preview then
      mermaid.preview_diagram(bufnr, temp_path .. ".png", M.config)
    end
  end

  mermaid.render_buffer(M.config, bufnr, on_complete)
end

return M
