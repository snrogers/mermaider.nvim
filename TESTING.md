# Testing mermaider.nvim

This document describes the testing approach for the mermaider.nvim plugin.

## Test Structure

Tests are written using the Busted BDD testing framework. Tests are located in the `spec` directory and use the `_spec.lua` suffix.

## Running Tests

Run all tests with:

```bash
busted
```

To run tests with verbose output:

```bash
busted -v
```

To run a specific test file:

```bash
busted spec/buffer_spec.lua
```

### Installing Busted

Busted can be installed with LuaRocks:

```bash
luarocks install busted
```

## Writing Tests

Tests are written in BDD style using the Busted framework. The basic structure is:

```lua
describe("module or component", function()
  describe("function or feature", function()
    it("should do something specific", function()
      -- Test code and assertions
      assert.equals(expected, actual)
    end)
  end)
end)
```

For more information, refer to the [Busted documentation](https://olivinelabs.com/busted/).

## Mocking Vim API

The tests mock the Vim API to test functionality without requiring a running Neovim instance.
This mocking is handled in `spec/helpers/init.lua`.

## Test Data

Test data including mock buffers with mermaid diagrams is defined in `spec/helpers/init.lua`.