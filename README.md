# Mermaider.nvim

![Wow!](https://github.com/snrogers/mermaider.nvim/blob/main/examples/image.png?raw=true)

A Neovim plugin for rendering [Mermaid.js](https://mermaid.js.org/) diagrams directly in your editor.

## Features

- Auto-renders diagrams on save or when requested
- Displays diagrams using [image.nvim](https://github.com/3rd/image.nvim) for in-editor visualization
- Inline rendering mode lets you toggle between code and diagram view
- Traditional split-window view option for side-by-side editing

## Requirements

- npx (for mermaid-cli)
- [image.nvim](https://github.com/3rd/image.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add to your `lua/plugins/` directory:

```lua
-- lua/plugins/mermaider.lua
return {
  "snrogers/mermaider.nvim",
  dependencies = {
    "3rd/image.nvim", -- Required for image display
  },
  config = function()
    require("mermaider").setup({
      -- Your config here (see Configuration section below)
    })
  end,
  ft = { "mmd", "mermaid" },
}
```

## Configuration

Here's a configuration with all available options and their default values:

```lua
require("mermaider").setup({
  -- Command to run the mermaid-cli
  -- {{OUT_FILE}} will be replaced with the output file path
  mermaider_cmd = 'npx -y -p @mermaid-js/mermaid-cli mmdc -o {{OUT_FILE}}.png -s 3',

  -- Directory for temporary files
  temp_dir = vim.fn.expand('$HOME/.cache/mermaider'),

  auto_render = true,          -- Auto render on save, BufEnter, BufWinEnter

  -- Mermaid diagram styling
  theme            = "forest",    -- "dark", "light", "forest", "neutral"
  background_color = "#1e1e2e", -- Background color for diagrams

  -- Window size settings
  max_width_window_percentage = 80,    -- Maximum width as percentage of window
  max_height_window_percentage = 80,   -- Maximum height as percentage of window
})
```

## Usage

### File Types

The plugin automatically recognizes files with `.mmd` and `.mermaid` extensions.

### Commands

- `:MermaiderRender` - Render the current mermaid diagram
- `:MermaiderPreview` - Preview the rendered diagram (inline or in split window based on configuration)
- `:MermaiderToggle` - Toggle between code view and diagram view when using inline rendering

### Keybindings

The plugin provides one default keybinding:

- `<leader>mt` - Toggle between code and diagram view (same as `:MermaiderToggle`)

## License

MIT

## Acknowledgments

- [Mermaid.js](https://mermaid.js.org/) for the awesome diagramming tool
- [image.nvim](https://github.com/3rd/image.nvim) for in-editor image display
