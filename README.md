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
return {
	"nounder/tree-copy.nvim",
	keys = {
		{
			"Y",
			function()
				require("tree-copy").copy_related_code()
			end,
			mode = "v",
			desc = "Copy related code",
		},
	},
}
```

## Usage

After installation, use `Y` in visual mode to copy related code. The plugin will analyze your selection and copy all related declarations and dependencies.
