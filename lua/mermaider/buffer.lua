-- lua/mermaider/buffer.lua
-- Text analysis for extracting mermaid diagrams from text content

local M = {}

-- Block info data structure
-- @class ChartInfo
-- @field content string: the mermaid chart content
-- @field start_line number: starting line in the text (0-indexed)
-- @field end_line number: ending line in the text (0-indexed)
-- @field ft string: detected filetype of the source

-- Extract mermaid code blocks using tree-sitter from markdown text
-- @param text string: text content to extract from
-- @param filetype string: filetype of the text content
-- @return table: list of ChartInfo objects
function M.get_mermaid_chart_info(text, filetype)
  if not text or text == "" then
    return {}
  end

  -- If filetype is mermaid, treat the entire text as a diagram
  if filetype == "mermaid" or filetype == "mmd" then
    -- Count lines in text
    local line_count = 0
    for _ in string.gmatch(text.."\n", "(.-)\n") do
      line_count = line_count + 1
    end

    return {
      {
        content = text,
        start_line = 0,
        end_line = line_count - 1,
        ft = filetype
      }
    }
  end

  -- For non-mermaid files, assuming tree-sitter is available
  -- This is where you would integrate tree-sitter parsing
  -- For now, using the regex approach for backward compatibility

  local charts = {}
  local lines = {}

  -- Split text into lines
  for line in string.gmatch(text.."\n", "(.-)\n") do
    table.insert(lines, line)
  end

  local in_mermaid_block = false
  local current_block = {}
  local start_line = 0

  for i, line in ipairs(lines) do
    local line_idx = i - 1 -- Convert to 0-indexed

    if not in_mermaid_block then
      -- Check for start of mermaid block
      if line:match("^%s*```%s*mermaid%s*$") then
        in_mermaid_block = true
        current_block = {}
        start_line = line_idx + 1 -- Start after the ```mermaid line
      end
    else
      -- Check for end of mermaid block
      if line:match("^%s*```%s*$") then
        in_mermaid_block = false
        if #current_block > 0 then
          local content = table.concat(current_block, "\n")
          table.insert(charts, {
            content = content,
            start_line = start_line,
            end_line = line_idx - 1, -- End before the ``` line
            ft = "markdown"
          })
        end
      else
        -- Add line to current block
        table.insert(current_block, line)
      end
    end
  end

  -- Handle case where text ends without closing the code block
  if in_mermaid_block and #current_block > 0 then
    local content = table.concat(current_block, "\n")
    table.insert(charts, {
      content = content,
      start_line = start_line,
      end_line = #lines - 1, -- End at last line
      ft = "markdown"
    })
  end

  return charts
end

return M
