#!/usr/bin/env nvim -l

local function test_complete_copy_functionality()
	print("=== Testing Complete Copy Functionality ===")

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

	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.api.nvim_buf_set_mark(bufnr, "<", 1, 0, {})
	vim.api.nvim_buf_set_mark(bufnr, ">", 3, 1, {})

	local tree_copy = require("tree-copy")

	vim.fn.setreg('"', "")

	tree_copy.copy_related_code()

	local copied = vim.fn.getreg('"')
	if #copied == 0 then
		print("✗ FAILED: Nothing was copied to register")
		os.exit(1)
	end

	if not string.find(copied, "main") then
		print("✗ FAILED: Copied content should contain 'main'")
		os.exit(1)
	end

	if not string.find(copied, "greet") then
		print("✗ FAILED: Copied content should contain 'greet'")
		os.exit(1)
	end

	print("✓ PASSED: Complete copy functionality test")
	return true
end

require("tree-copy").setup()
local success = test_complete_copy_functionality()
if not success then
	os.exit(1)
end
