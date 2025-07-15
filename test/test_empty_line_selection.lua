local function test_empty_line_selection()
	print("=== Testing Empty Line Selection (Root Node Rejection) ===")

	-- Read the fixture file
	local fixture_path = "/Users/rg/Projects/tree-copy.nvim/test/fixture_single_module.ts"
	local file = io.open(fixture_path, "r")
	if not file then
		print("✗ FAILED: Could not open fixture file")
		os.exit(1)
	end
	local content = file:read("*all")
	file:close()

	-- Create buffer and set content
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
	vim.bo[bufnr].filetype = "typescript"

	-- Set up the plugin
	local tree_copy = require("tree-copy")
	tree_copy.setup()

	-- Wait for treesitter to be ready
	local max_wait = 50
	local wait_count = 0
	while wait_count < max_wait do
		local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "typescript")
		if ok and parser then
			break
		end
		vim.wait(50)
		wait_count = wait_count + 1
	end

	-- Test Case 1: Select empty lines around main function (should not copy everything)
	print("\n=== Test Case 1: Empty Lines Around Main Function ===")

	-- The main function is around line 48-50, let's select lines 47-51 (including empty lines)
	-- This should find the main function, not the root node
	local start_pos = { 0, 47, 1, 0 } -- Line 47
	local end_pos = { 0, 51, 1, 0 } -- Line 51

	-- Clear register
	vim.fn.setreg('"', "")

	-- Call with explicit bounds
	tree_copy.copy_related_code(start_pos, end_pos)

	-- Check what was copied
	local copied = vim.fn.getreg('"')
	if #copied == 0 then
		print("✓ PASSED: Nothing copied for empty line selection (expected behavior)")
		print("This means the root node was properly rejected")
	else
		-- If something was copied, it should be specific functions, not everything
		local blocks = vim.split(copied, "\n\n")
		local non_empty_blocks = {}
		for _, block in ipairs(blocks) do
			if string.match(block, "%S") then
				table.insert(non_empty_blocks, block)
			end
		end

		print("Copied " .. #non_empty_blocks .. " blocks:")
		for i, block in ipairs(non_empty_blocks) do
			local preview = string.sub(block, 1, 50):gsub("\n", " ")
			print("  Block " .. i .. ": " .. preview .. "...")
		end

		-- Should not copy everything (more than 5 blocks would indicate root node selection)
		if #non_empty_blocks > 5 then
			print("✗ FAILED: Too many blocks copied (" .. #non_empty_blocks .. "), likely selected root node")
			print("Full copied content:")
			print(copied)
			os.exit(1)
		end

		-- Should contain main function if anything is copied
		if not string.find(copied, "main") then
			print("✗ FAILED: If anything is copied, it should contain main function")
			os.exit(1)
		end

		print("✓ PASSED: Copied specific functions only, not everything")
	end

	-- Test Case 2: Select whitespace before a function
	print("\n=== Test Case 2: Whitespace Before Function ===")

	-- Select whitespace before the greet function (around line 54)
	start_pos = { 0, 53, 1, 0 } -- Line before greet
	end_pos = { 0, 54, 1, 0 } -- Line with greet

	vim.fn.setreg('"', "")
	tree_copy.copy_related_code(start_pos, end_pos)

	copied = vim.fn.getreg('"')
	if #copied == 0 then
		print("✓ PASSED: Nothing copied for whitespace selection")
	else
		-- Should be specific, not everything
		local blocks = vim.split(copied, "\n\n")
		local non_empty_blocks = {}
		for _, block in ipairs(blocks) do
			if string.match(block, "%S") then
				table.insert(non_empty_blocks, block)
			end
		end

		if #non_empty_blocks > 5 then
			print("✗ FAILED: Too many blocks copied for whitespace selection")
			os.exit(1)
		end

		print("✓ PASSED: Whitespace selection copied specific content only")
	end

	-- Test Case 3: Select trailing empty lines after a function
	print("\n=== Test Case 3: Trailing Empty Lines After Function ===")

	-- Select the main function plus trailing empty lines
	start_pos = { 0, 48, 1, 0 } -- Main function line
	end_pos = { 0, 52, 1, 0 } -- A few lines after

	vim.fn.setreg('"', "")
	tree_copy.copy_related_code(start_pos, end_pos)

	copied = vim.fn.getreg('"')
	if #copied == 0 then
		print("✗ FAILED: Should copy main function even with trailing lines")
		os.exit(1)
	end

	-- Should contain main and related functions, but not everything
	local blocks = vim.split(copied, "\n\n")
	local non_empty_blocks = {}
	for _, block in ipairs(blocks) do
		if string.match(block, "%S") then
			table.insert(non_empty_blocks, block)
		end
	end

	if #non_empty_blocks > 5 then
		print("✗ FAILED: Too many blocks copied with trailing lines (" .. #non_empty_blocks .. ")")
		print("This suggests root node was selected")
		os.exit(1)
	end

	if not string.find(copied, "main") then
		print("✗ FAILED: Should contain main function")
		os.exit(1)
	end

	print("✓ PASSED: Main function with trailing lines copied correctly")
	print("Copied " .. #non_empty_blocks .. " blocks as expected")

	-- Test Case 4: Select only empty lines (should copy nothing or reject gracefully)
	print("\n=== Test Case 4: Only Empty Lines ===")

	-- Find some empty lines in the file (around line 24-25 area)
	start_pos = { 0, 24, 1, 0 }
	end_pos = { 0, 25, 1, 0 }

	vim.fn.setreg('"', "")
	tree_copy.copy_related_code(start_pos, end_pos)

	copied = vim.fn.getreg('"')
	if #copied == 0 then
		print("✓ PASSED: Empty line selection copied nothing (expected)")
	else
		-- If something was copied, make sure it's not everything
		local blocks = vim.split(copied, "\n\n")
		local non_empty_blocks = {}
		for _, block in ipairs(blocks) do
			if string.match(block, "%S") then
				table.insert(non_empty_blocks, block)
			end
		end

		if #non_empty_blocks > 5 then
			print("✗ FAILED: Empty line selection copied too much (" .. #non_empty_blocks .. " blocks)")
			os.exit(1)
		end

		print("✓ PASSED: Empty line selection copied minimal content")
	end

	print("\n✓ PASSED: All empty line selection tests")
	return true
end

require("tree-copy").setup()
local success = test_empty_line_selection()
if not success then
	os.exit(1)
end
