-- spec/helpers/init.lua
-- Test helpers for mermaider.nvim

local helpers = {}

-- Test buffers for simulation
helpers.buffers = {
  -- Buffer 1: Mermaid file
  [1] = {
    filetype = "mermaid",
    "graph TD;",
    "    A-->B;",
    "    A-->C;",
    "    B-->D;",
    "    C-->D;"
  },

  -- Buffer 2: Markdown with mermaid blocks
  [2] = {
    filetype = "markdown",
    "# Test Markdown",
    "",
    "Some text here",
    "",
    "```mermaid",
    "graph TD;",
    "    A-->B;",
    "    A-->C;",
    "```",
    "",
    "More text",
    "",
    "```mermaid",
    "sequenceDiagram",
    "    Alice->>John: Hello John, how are you?",
    "    John-->>Alice: Great!",
    "```",
    "",
    "End of file"
  }
}

-- Cursor positions for simulation
helpers.cursors = {
  [0] = {1, 0} -- Default cursor position (line 1, col 0)
}

-- Set up the mock for vim global
helpers.setup_vim_mock = function()
  -- Only set up if not already defined (to avoid overriding in Neovim)
  if not vim then
    _G.vim = {
      api = {
        nvim_buf_get_lines = function(bufnr, start_line, end_line, strict)
          -- Mock implementation that will return lines from our test data
          if not helpers.buffers[bufnr] then return {} end

          if end_line == -1 then end_line = #helpers.buffers[bufnr] end

          local result = {}
          for i = start_line + 1, end_line do -- Convert 0-based to 1-based
            table.insert(result, helpers.buffers[bufnr][i])
          end
          return result
        end,

        nvim_buf_line_count = function(bufnr)
          return helpers.buffers[bufnr] and #helpers.buffers[bufnr] or 0
        end,

        nvim_win_get_cursor = function(winid)
          return helpers.cursors[winid] or {1, 0}
        end
      },

      bo = setmetatable({}, {
        __index = function(t, bufnr)
          if helpers.buffers[bufnr] then
            return { filetype = helpers.buffers[bufnr].filetype or "markdown" }
          end
          return {}
        end
      })
    }
  end
end

return helpers
