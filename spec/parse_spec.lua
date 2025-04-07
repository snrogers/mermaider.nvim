-- spec/parse_spec.lua
-- Tests for parse.lua using busted

-- Load the module to test
local parse = require("mermaider.parse")

-- Test data
local test_data = {
  -- Mermaid file content
  mermaid_file = [[graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;]],

  -- Markdown with mermaid blocks
  markdown_file = [[# Test Markdown

Some text here

```mermaid
graph TD;
    A-->B;
    A-->C;
```

More text

```mermaid
sequenceDiagram
    Alice->>John: Hello John, how are you?
    John-->>Alice: Great!
```

End of file]]
}

-- Tests
describe("parse", function()
  describe("get_mermaid_chart_info", function()
    it("extracts full content info from mermaid files", function()
      local charts = parse.get_mermaid_chart_info(test_data.mermaid_file, "mermaid")
      assert.equals(1, #charts)
      assert.equals(test_data.mermaid_file, charts[1].content)
      assert.equals(0, charts[1].start_line)
      assert.equals(4, charts[1].end_line)
      assert.equals("mermaid", charts[1].ft)
    end)

    it("extracts mermaid blocks info from markdown", function()
      local charts = parse.get_mermaid_chart_info(test_data.markdown_file, "markdown")
      assert.equals(2, #charts)
      assert.equals("graph TD;\n    A-->B;\n    A-->C;", charts[1].content)
      assert.equals("sequenceDiagram\n    Alice->>John: Hello John, how are you?\n    John-->>Alice: Great!", charts[2].content)
      assert.equals(5, charts[1].start_line)
      assert.equals(7, charts[1].end_line)
      assert.equals(13, charts[2].start_line)
      assert.equals(15, charts[2].end_line)
      assert.equals("markdown", charts[1].ft)
      assert.equals("markdown", charts[2].ft)
    end)
  end)
end)
