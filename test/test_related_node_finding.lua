#!/usr/bin/env nvim -l

local function test_related_node_finding()
	print("=== Testing Related Node Finding ===")

	local test_content = [[function main() {
	greet()
}

function greet() {
	console.log("Hello world!")
}

const message = "Welcome";]]

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_content, "\n"))
	vim.bo[bufnr].filetype = "javascript"

	local parsers = require("tree-copy.parsers")
	local parser = parsers.get_parser("javascript")
	local identifiers = { "main", "greet" }

	local related_nodes = parsers.find_related_nodes("javascript", parser, identifiers)
	if #related_nodes == 0 then
		print("✗ FAILED: No related nodes found")
		os.exit(1)
	end

	if #related_nodes < 2 then
		print("✗ FAILED: Should find at least main and greet functions, found: " .. #related_nodes)
		os.exit(1)
	end

	print("✓ PASSED: Related node finding test")
	return true
end

require("tree-copy").setup()
local success = test_related_node_finding()
if not success then
	os.exit(1)
end
