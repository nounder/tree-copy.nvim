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

	local tree_copy = require("tree-copy")

	vim.fn.setreg('"', "")

	-- Pass the selection directly instead of relying on visual marks
	local start_pos = { 0, 1, 1, 0 }  -- line 1, col 1 (1-based for getpos format)
	local end_pos = { 0, 3, 2, 0 }    -- line 3, col 2 (1-based for getpos format)
	tree_copy.copy_related_code(start_pos, end_pos)

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
