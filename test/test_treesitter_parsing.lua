#!/usr/bin/env nvim -l

local function test_treesitter_parsing()
	print("=== Testing Tree-sitter Parsing ===")

	local test_content = [[function main() {
	greet()
}

function greet() {
	console.log("Hello world!")
}]]

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_content, "\n"))
	vim.bo[bufnr].filetype = "javascript"

	local parsers = require("tree-copy.parsers")
	local parser = parsers.get_parser("javascript")
	local tree = parser:parse()[1]
	local root = tree:root()

	if root:type() ~= "program" then
		print("✗ FAILED: Expected program node, got: " .. root:type())
		os.exit(1)
	end

	if root:child_count() == 0 then
		print("✗ FAILED: Root node has no children")
		os.exit(1)
	end

	print("✓ PASSED: Tree-sitter parsing test")
	return true
end

require("tree-copy").setup()
local success = test_treesitter_parsing()
if not success then
	os.exit(1)
end
