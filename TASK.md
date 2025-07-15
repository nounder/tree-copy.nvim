**Context:**
You are in neovim starter template. You are implementing tree-copy.nvim plugin that uses tree-sitter to copy all related code that is currently selected. We will focus on supporting typescript but we will want to add support for other langauges in the future so structure the code to account for that.

**Task:**
Implement a function that will bind to visual <leader>y that takes treesitter node under current selection and extracts all identifiers from it and searches for all nodes in the buffer that reference that idenitifer (like import_clause and namespace_import in case of typescript). it then concates them and puts them in a register to be pasted.o

