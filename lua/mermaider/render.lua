-- lua/mermaider/render.lua
-- Rendering logic for Mermaider

local M = {}

local uv  = vim.uv
local api = vim.api

local files    = require("mermaider.files")
local commands = require("mermaider.commands")
local status   = require("mermaider.status")
local utils    = require("mermaider.utils")

-- Table to keep track of active render jobs
local active_jobs = {}

--- Render the buffer content as a Mermaid diagram
--- @param config table: plugin configuration
--- @param bufnr number: buffer id
--- @param callback function: callback with (success, result) parameters
function M.render_charts_in_buffer(config, bufnr, callback)
  assert(api.nvim_buf_is_valid(bufnr), "Invalid buffer: " .. bufnr)

  status.set_status(bufnr, status.STATUS.RENDERING)

  local buffer_content = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  active_jobs[bufnr]   = commands.execute_render_job(config, buffer_content, callback, bufnr, output_file)
end

--- Cancel a specific render job
--- @param bufnr number: buffer id
function M.cancel_render(bufnr)
  local job = active_jobs[bufnr]
  if job and not job:is_closing() then
    job:close()
    active_jobs[bufnr] = nil
    status.set_status(bufnr, status.STATUS.IDLE)
    utils.log_info("Render cancelled for buffer " .. bufnr)
  end
end

-- Cancel all active render jobs
function M.cancel_all_jobs()
  for bufnr, job in pairs(active_jobs) do
    if job and not job:is_closing() then
      job:close()
      utils.log_info("Render job cancelled for buffer " .. bufnr)
    end
  end
  active_jobs = {}
end

return M
