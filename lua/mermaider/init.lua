local M = {}

local api   = vim.api
local image = require("image")

local diagram       = require("mermaider.diagram")
local config_module = require("mermaider.config")
local render        = require("mermaider.render")
local utils         = require("mermaider.utils")
local file          = require("mermaider.file")


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
  local npx_found_ok = utils.is_program_installed("npx")
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
        local bufnr = api.nvim_get_current_buf()
        render.render_mmd_buffer(M._config, bufnr)
      end, 500), -- Throttle to 500ms
    })

    api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = augroup,
      pattern = { "*.mmd", "*.mermaid" },
      callback = function()
        local bufnr = api.nvim_get_current_buf()
        render.render_mmd_buffer(M._config, bufnr)
      end,
    })
  end

  -- On Buffer Delete
  api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    pattern = { "*.mmd", "*.mermaid" },
    callback = function(ev)
      render.fork_render_job(ev.buf)
      diagram.clear_image(ev.buf, vim.api.nvim_get_current_win())
      file.tempfiles[ev.buf] = nil
    end,
  })

  -- Clear all images On Program Exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      image.clear()
      file.cleanup_temp_files(file._tempfiles)
    end,
  })
end

function M._setup_cmds()
  api.nvim_create_user_command("MermaiderRender", function()
    local bufnr = api.nvim_get_current_buf()
    render.render_charts_in_buffer(M._config, bufnr)
  end, { desc = "Render the current mermaid diagram" })
end


return M
