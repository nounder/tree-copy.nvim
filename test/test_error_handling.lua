#!/usr/bin/env nvim -l

local function test_error_handling()
	print("=== Testing Error Handling ===")

	local tree_copy = require("tree-copy")

	-- Test with unsupported filetype
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'print("hello")' })
	vim.bo[bufnr].filetype = "python"

	-- This should not crash
	local ok, err = pcall(tree_copy.copy_related_code)
	if not ok then
		print("✗ FAILED: copy_related_code should not crash on unsupported filetype")
		print("  Error: " .. tostring(err))
		os.exit(1)
	end

	print("✓ PASSED: Error handling test")
	return true
end

require("tree-copy").setup()
local success = test_error_handling()
if not success then
	os.exit(1)
end