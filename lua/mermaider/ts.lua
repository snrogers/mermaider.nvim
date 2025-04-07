local ts = require('vim.treesitter')

local M = {}

--- Extracts Mermaid code blocks from a Markdown string using Tree-sitter.
--- This function parses the input Markdown string and identifies fenced code blocks
--- (```) tagged with the 'mermaid' language identifier, returning their contents.
---
--- @param md_string string The Markdown string to parse. Must be non-empty.
--- @return table A table containing the contents of all Mermaid code blocks found.
---               Each entry is a string representing the code inside a ```mermaid block.
---               Returns an empty table if no Mermaid blocks are found or if parsing fails.
--- @usage
---   local md = [[```mermaid\ngraph TD\nA-->B\n```]]
---   local blocks = extract_mermaid_from_markdown(md)
---   for i, block in ipairs(blocks) do print(block) end
--- @requires Tree-sitter parser for 'markdown' installed (:TSInstall markdown)
--- @note Prints error messages to Neovim if input is invalid or parser is unavailable.
function M.extract_mermaid_from_markdown(md_string)
  if type(md_string) ~= 'string' or md_string == '' then
    print('Error: Input must be a non-empty string')
    return {}
  end

  local lang = 'markdown'
  if not pcall(function() ts.language.require_language(lang) end) then
    print('Error: Tree-sitter parser for "markdown" is not installed. Run :TSInstall markdown')
    return {}
  end

  local parser = ts.get_parser(0, lang)
  local tree = parser:parse({
    source = function()
      return md_string
    end
  })[1]

  if not tree then
    print('Error: Failed to parse Markdown string')
    return {}
  end

  local query_str = [[
    (fenced_code_block
      (info_string
        (language) @lang (#eq? @lang "mermaid"))
      (code_fence_content) @content)
  ]]
  local query = ts.query.parse(lang, query_str)

  local mermaid_blocks = {}
  for id, node, metadata in query:iter_captures(tree:root(), 0) do
    if query.captures[id] == 'content' then
      local text = ts.get_node_text(node, md_string)
      if text then
        table.insert(mermaid_blocks, text)
      end
    end
  end

  return mermaid_blocks
end

return M
