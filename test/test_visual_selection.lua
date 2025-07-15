local function test_visual_selection()
	print("=== Testing Visual Selection Detection ===")

	local tree_copy = require("tree-copy")

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "function main() {", "  greet()", "}" })

	vim.api.nvim_buf_set_mark(bufnr, "<", 1, 0, {})
	vim.api.nvim_buf_set_mark(bufnr, ">", 3, 1, {})

	local start_row, start_col, end_row, end_col = tree_copy.get_visual_selection()

	if start_row < 0 then
		print("✗ FAILED: Start row should be non-negative, got: " .. start_row)
		os.exit(1)
	end

	if end_row < start_row then
		print("✗ FAILED: End row should be >= start row, got start:" .. start_row .. " end:" .. end_row)
		os.exit(1)
	end

	print("✓ PASSED: Visual selection detection test")
	return true
end

require("tree-copy").setup()
local success = test_visual_selection()
if not success then
	os.exit(1)
end
