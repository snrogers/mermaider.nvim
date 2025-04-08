-- lua/mermaider/render.lua
-- Rendering logic for Mermaider

local M = {}

local uv  = vim.uv
local api = vim.api

local commands = require("mermaider.command")
local status   = require("mermaider.status")


--- Table to keep track of active render jobs
--- @type table<number, vim.SystemObj>
local active_jobs = {}

--- Render the buffer content as a Mermaid diagram
--- @param config table: plugin configuration
--- @param bufnr number: buffer id
function M.render_charts_in_buffer(config, bufnr)
  assert(api.nvim_buf_is_valid(bufnr), "Invalid buffer: " .. bufnr)

  status.set_status(bufnr, status.STATUS.RENDERING)

  local buffer_content = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  commands.execute_render_job(config, buffer_content, bufnr)
end
return M
