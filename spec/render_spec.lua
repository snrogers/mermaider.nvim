local render = require("mermaider.render")
local files = require("mermaider.files")
local commands = require("mermaider.commands")

describe("render", function()
  describe("render_charts_in_buffer", function()
    it("pipes content to stdin", function()
      local config = { mermaider_cmd = 'npx -y -p @mermaid-js/mermaid-cli mmdc -o {{OUT_FILE}}.png' }
      local bufnr = 1 -- Use test buffer from spec/helpers/init.lua
      local callback_called = false
      local callback = function(success, result)
        callback_called = true
        assert.is_true(success)
        assert.is_string(result)
      end
      render.render_charts_in_buffer(config, bufnr, callback)
      assert.is_true(callback_called)
    end)
  end)
end)
