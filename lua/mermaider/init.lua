-- lua/mermaider/init.lua
-- Main entry point for Mermaider plugin, now focused on image.nvim

local M = {}
local api = vim.api
local fn  = vim.fn

-- Import modules
local config_module     = require("mermaider.config")
local files             = require("mermaider.files")
local image_integration = require("mermaider.image_integration")
local mermaid           = require("mermaider.mermaid")
local render            = require("mermaider.render")
local utils             = require("mermaider.utils")

M.config = {}
M.tempfiles = {}

function M.setup(opts)
  M.config = config_module.setup(opts)
  M.check_dependencies()
  image_integration.setup(M.config)

  api.nvim_create_user_command("MermaiderRender", function()
    M.render_current_buffer()
  end, { desc = "Render the current mermaid diagram" })

  api.nvim_create_user_command("MermaiderPreview", function()
    local bufnr = api.nvim_get_current_buf()
    local image_path = files.get_temp_file_path(M.config, bufnr) .. ".png"
    mermaid.preview_diagram(bufnr, image_path, M.config)
  end, { desc = "Preview the current mermaid diagram" })

  api.nvim_create_user_command("MermaiderToggle", function()
    local bufnr = api.nvim_get_current_buf()
    image_integration.toggle_preview(bufnr)
  end, { desc = "Toggle between mermaid code and preview" })

  vim.keymap.set('n', '<leader>mt', function()
    vim.cmd('MermaiderToggle')
  end, { desc = "Toggle mermaid preview", silent = true })

  M.setup_autocmds()
  utils.safe_notify("Mermaider plugin loaded with image.nvim", vim.log.levels.INFO)
end

function M.check_dependencies()
  if not utils.is_program_installed("npx") then
    utils.safe_notify(
      "npx command not found. Please install Node.js and npm.",
      vim.log.levels.WARN
    )
  end

  if not image_integration.is_available() then
    utils.safe_notify(
      "image.nvim not available. Please ensure it's installed and configured.",
      vim.log.levels.ERROR
    )
  end
end

function M.setup_autocmds()
  local augroup = api.nvim_create_augroup("Mermaider", { clear = true })

  if M.config.auto_render then
    api.nvim_create_autocmd({ "BufWritePost" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        M.render_current_buffer()
      end,
    })
  end

  if M.config.auto_render_on_open then
    api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        M.render_current_buffer()
      end,
    })
  end

  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      render.cancel_all_jobs()
      image_integration.clear_images()
      files.cleanup_temp_files(M.tempfiles)
    end,
  })

  api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      render.cancel_render(ev.buf)
      image_integration.clear_image(ev.buf, vim.api.nvim_get_current_win())
      M.tempfiles[ev.buf] = nil
    end,
  })

  api.nvim_create_autocmd({ "WinResized" }, {
    group = augroup,
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if M.config.inline_render and M.image_objects[buf] then
          local image_path = files.get_temp_file_path(M.config, buf) .. ".png"
          image_integration.render_inline(buf, image_path, M.config)
        end
      end
    end,
  })
end

function M.render_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  local temp_path = files.get_temp_file_path(M.config, bufnr)
  M.tempfiles[bufnr] = temp_path

  local on_complete = function(success, result)
    if success and M.config.auto_preview then
      mermaid.preview_diagram(bufnr, temp_path .. ".png", M.config)
    end
  end

  render.render_buffer(M.config, bufnr, on_complete)
end

return M
