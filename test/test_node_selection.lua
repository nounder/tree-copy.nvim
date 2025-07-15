#!/usr/bin/env nvim -l

local function test_node_selection()
	print("=== Testing Tree-sitter Node Selection ===")

	local test_content = [[function main() {
	greet()
}]]

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_content, "\n"))
	vim.bo[bufnr].filetype = "javascript"

	local parsers = require("tree-copy.parsers")
	local tree_copy = require("tree-copy")
	local parser = parsers.get_parser("javascript")

	local node = tree_copy.get_node_at_selection(parser, 0, 0, 2, 1)
	if node == nil then
		print("✗ FAILED: No node found for function selection")
		os.exit(1)
	end

	local node_text = vim.treesitter.get_node_text(node, bufnr)
	if not string.find(node_text, "main") then
		print("✗ FAILED: Selected node should contain 'main', got: " .. node_text)
		os.exit(1)
	end

	print("✓ PASSED: Node selection test")
	return true
end

require("tree-copy").setup()
local success = test_node_selection()
if not success then
	os.exit(1)
end
