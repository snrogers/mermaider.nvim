-- lua/mermaider/init.lua
-- Main entry point for Mermaider plugin, now focused on image.nvim

local M = {}

local api = vim.api

local config_module     = require("mermaider.config")
local render            = require("mermaider.render")
local utils             = require("mermaider.utils")


-- ----------------------------------------------------------------- --
-- Public API
-- ----------------------------------------------------------------- --

function M.setup(opts)
  M._config = config_module.setup(opts)
  M._check_dependencies()

  M._setup_cmds()
  M._setup_autocmds()

  utils.log_debug("Mermaider plugin loaded")
end

-- ----------------------------------------------------------------- --
-- Private API
-- ----------------------------------------------------------------- --

M._config = config_module.defaults -- Pre-init the config

function M._check_dependencies()
  local npx_found_ok = utils._is_program_installed("npx")
  assert(npx_found_ok, "npx not found")

  local image_nvim_found_ok = pcall(require, "image")
  assert(image_nvim_found_ok, "image.nvim not found")
end

function M._setup_autocmds()
  local augroup = api.nvim_create_augroup("Mermaider", { clear = true })

  -- Redraw on Save/Focus/Open?
  if M._config.auto_render then
    api.nvim_create_autocmd({ "BufWritePost" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = utils.throttle(function()
        M._render_current_buffer()
      end, 500), -- Throttle to 500ms
    })

    api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        M._render_current_buffer()
      end,
    })
  end
end

function M._setup_cmds()
  api.nvim_create_user_command("MermaiderRender", function()
    M._render_current_buffer()
  end, { desc = "Render the current mermaid diagram" })
end

function M._render_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  render.render_charts_in_buffer(M._config, bufnr)
end

return M
