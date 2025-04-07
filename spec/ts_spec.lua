local ts = require("mermaider.ts")

describe("ts", function()
  it("extracts mermaid blocks from markdown", function()
    local markdown_string = [[
# Example Markdown

Some text here.

```mermaid
graph TD
  A --> B
```

More text.

```mermaid
sequenceDiagram
  Alice->>Bob: Hello
```

```python
print("Not Mermaid")
```
    ]]
  end)
end)
