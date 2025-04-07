-- lua/mermaider/init.lua
-- Main entry point for Mermaider plugin, now focused on image.nvim

local M = {}

local api = vim.api
local fn  = vim.fn

local config_module     = require("mermaider.config")
local files             = require("mermaider.files")
local image_integration = require("mermaider.image_integration")
local mermaid           = require("mermaider.mermaid")
local render            = require("mermaider.render")
local utils             = require("mermaider.utils")



-- ----------------------------------------------------------------- --
-- Public API
-- ----------------------------------------------------------------- --
function M.setup(opts)
  M._config = config_module.setup(opts)
  M._check_dependencies()

  api.nvim_create_user_command("MermaiderRender", function()
    M._render_current_buffer()
  end, { desc = "Render the current mermaid diagram" })

  api.nvim_create_user_command("MermaiderToggle", function()
    local bufnr = api.nvim_get_current_buf()
    image_integration.toggle_preview(bufnr)
  end, { desc = "Toggle between mermaid code and preview" })

  vim.keymap.set('n', '<leader>mt', function()
    vim.cmd('MermaiderToggle')
  end, { desc = "Toggle mermaid preview", silent = true })

  M._setup_autocmds()
  utils.safe_notify("Mermaider plugin loaded with image.nvim", vim.log.levels.INFO)
end

-- ----------------------------------------------------------------- --
-- Private API
-- ----------------------------------------------------------------- --
M._config    = {}
M._tempfiles = {}


function M._check_dependencies()
  local npx_found_ok = utils.is_program_installed("npx")
  assert(npx_found_ok, "npx not found")

  local image_nvim_found_ok = image_integration.is_available()
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

  -- On Buffer Delete
  api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      render.cancel_render(ev.buf)
      image_integration.clear_image(ev.buf, vim.api.nvim_get_current_win())
      M._tempfiles[ev.buf] = nil
    end,
  })

  -- On Program Exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      render.cancel_all_jobs()
      image_integration.clear_images()
      files.cleanup_temp_files(M._tempfiles)
    end,
  })
end

function M._render_current_buffer()
  local bufnr = api.nvim_get_current_buf()

  local on_complete = function(success, result)
    assert(success, "Failed to render diagram")

    utils.log_debug("Render callback: success=" .. tostring(success) .. ", result=" .. tostring(result))

    if not success then
      utils.log_error("Render failed with: " .. result)
    else
      M._tempfiles[bufnr] = result
      if M._config.auto_preview then
        mermaid.preview_diagram(bufnr, result, M._config)
      end
    end
  end

  render.render_charts_in_buffer(M._config, bufnr, on_complete)
end

return M
