# hello.nvim

A Neovim plugin starter template.

## Features

- Prints "Hello World" on initialization
- Provides a keybinding (`<leader>hw`) to open a buffer with "Hello World" and current date

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "nounder/hello.nvim",
  config = function()
    require("hello").setup()
  end,
}
```

## Usage

After installation, the plugin will print "Hello World" when initialized. Use `<leader>hw` to open a buffer displaying "Hello World" and the current date.