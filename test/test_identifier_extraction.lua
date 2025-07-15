#!/usr/bin/env nvim -l

local function test_identifier_extraction()
	print("=== Testing Identifier Extraction ===")

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

	local identifiers = parsers.extract_identifiers("javascript", node)
	if #identifiers == 0 then
		print("✗ FAILED: No identifiers extracted")
		os.exit(1)
	end

	local has_main = false
	local has_greet = false
	for _, id in ipairs(identifiers) do
		if id == "main" then
			has_main = true
		end
		if id == "greet" then
			has_greet = true
		end
	end

	if not has_main then
		print("✗ FAILED: Should extract 'main' identifier")
		os.exit(1)
	end

	if not has_greet then
		print("✗ FAILED: Should extract 'greet' identifier")
		os.exit(1)
	end

	print("✓ PASSED: Identifier extraction test")
	return true
end

require("tree-copy").setup()
local success = test_identifier_extraction()
if not success then
	os.exit(1)
end
