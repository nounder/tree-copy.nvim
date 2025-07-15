# tree-copy.nvim

A Neovim plugin for copying related code using tree-sitter.

## Features

- Copies related code based on tree-sitter analysis
- Supports TypeScript and other languages
- Intelligent identifier extraction and dependency resolution
- Finds containing functions when selecting function calls

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/tree-copy.nvim",
  keys = {
    { "<leader>y", function() require("tree-copy").copy_related_code_visual() end, mode = "v", desc = "Copy related code" },
  },
}
```

## Usage

After installation, use `<leader>y` in visual mode to copy related code. The plugin will analyze your selection and copy all related declarations and dependencies.