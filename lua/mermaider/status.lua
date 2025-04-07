-- lua/mermaider/status.lua
-- Status management for render operations

local M = {}
local api = vim.api

-- Status constants
M.STATUS = {
  IDLE = "idle",
  RENDERING = "rendering",
  SUCCESS = "success",
  ERROR = "error"
}

-- Tracking variables
local render_status = {}
local status_ns = nil

-- Initialize the status namespace for highlights
function M.init()
  -- Create highlight namespace if it doesn't exist
  if not status_ns then
    status_ns = api.nvim_create_namespace("MermaiderStatus")

    -- Set up highlight groups if they don't exist
    -- In a future version, these could be configurable
    vim.cmd([[
      highlight default MermaiderStatusIdle guifg=#7c6f64 ctermfg=gray
      highlight default MermaiderStatusRendering guifg=#fabd2f ctermfg=yellow
      highlight default MermaiderStatusSuccess guifg=#b8bb26 ctermfg=green
      highlight default MermaiderStatusError guifg=#fb4934 ctermfg=red
    ]])
  end
end

--- Get the current status for a buffer
--- @param bufnr number: buffer id
--- @return string: status string (one of M.STATUS values)
function M.get_status(bufnr)
  return render_status[bufnr] or M.STATUS.IDLE
end

--- Set the status for a buffer
--- @param bufnr number: buffer id
--- @param status string: status to set (one of M.STATUS values)
--- @param message string|nil: optional status message
function M.set_status(bufnr, status, message)
  -- Initialize if needed
  M.init()

  -- Update status
  render_status[bufnr] = status

  -- Get appropriate highlight group
  local hl_group = "MermaiderStatus" .. status:sub(1, 1):upper() .. status:sub(2)

  -- Format status text
  local status_text = "[Mermaider: " .. status
  if message then
    status_text = status_text .. " - " .. message
  end
  status_text = status_text .. "]"

  -- Schedule the buffer operations to run in the main loop, not in a fast event
  vim.schedule(function()
    if api.nvim_buf_is_valid(bufnr) then
      -- Clear existing status
      api.nvim_buf_clear_namespace(bufnr, status_ns, 0, -1)

      -- Set virtual text at the end of the first line
      local line = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
      api.nvim_buf_set_virtual_text(
        bufnr,
        status_ns,
        0,  -- Line number (first line)
        {{ " " .. status_text, hl_group }},
        {}
      )
    end
  end)

  -- Schedule cleanup for success/error states
  if status == M.STATUS.SUCCESS or status == M.STATUS.ERROR then
    vim.defer_fn(function()
      if api.nvim_buf_is_valid(bufnr) and render_status[bufnr] == status then
        vim.schedule(function()
          if api.nvim_buf_is_valid(bufnr) then
            api.nvim_buf_clear_namespace(bufnr, status_ns, 0, -1)
          end
          render_status[bufnr] = M.STATUS.IDLE
        end)
      end
    end, 1000)  -- Clear after 1 second
  end
end

--- Clear status for a buffer
--- @param bufnr number: buffer id
function M.clear_status(bufnr)
  if status_ns then
    vim.schedule(function()
      if api.nvim_buf_is_valid(bufnr) then
        api.nvim_buf_clear_namespace(bufnr, status_ns, 0, -1)
      end
    end)
  end
  render_status[bufnr] = M.STATUS.IDLE
end

return M
