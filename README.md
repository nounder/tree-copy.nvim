# tree-copy.nvim

Copy code with its symbolic dependencies in one go!

![](./doc/explainer.png)

Ever wanted to copy a fragment of a code to a new file and ended up fighting with import statements, missing local functions and variables? This plugin copies all symbols used in a code fragment you want to make refactoring a breeze!

Only works with JavaScript/TypeScript for now. More languages can be added in `parsers/` directory.

Plugin is still in development so it's not perfect. I invite you to try it, report issues, and make PRs :)

## Features

- Copies related code based on tree-sitter
- Intelligent identifier extraction and dependency resolution

## Install

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
