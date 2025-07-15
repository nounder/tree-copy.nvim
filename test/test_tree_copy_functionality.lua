local function print_test_result(test_name, passed, message)
	local status = passed and "PASS" or "FAIL"
	print(string.format("[%s] %s: %s", status, test_name, message or ""))
end

local function setup_plugin()
	-- Plugin should be available via LUA_PATH when test is run
	-- No setup() call needed for basic functionality
end

local function test_copy_grid_function_and_references()
	print("\n=== Testing copy grid function and all its references ===")

	setup_plugin()
	local test_passed = true
	local error_message = ""
	local success, err = pcall(function()
		local fixture_path = vim.fn.fnamemodify("./test/fixtures/module.ts", ":p")

		-- Open the fixture file
		vim.cmd("edit " .. vim.fn.fnameescape(fixture_path))
		vim.bo.filetype = "typescript"

		-- Wait for treesitter to parse
		vim.wait(1000, function()
			local parser = vim.treesitter.get_parser(0, "typescript")
			if parser then
				parser:parse()
				return true
			end
			return false
		end)

		-- Navigate to the createGrid function (around line 35)
		vim.fn.search("export function createGrid(")
		local line = vim.fn.line(".")
		vim.fn.cursor(line, 1)

		-- Get the current cursor position
		local cursor_line = vim.fn.line(".")

		-- Select the entire grid function using visual mode
		vim.cmd("normal! V")

		-- Find the end of the function by looking for the closing brace
		local start_line = vim.fn.line(".")
		local current_line = start_line
		local brace_count = 0
		local found_opening = false

		while current_line <= vim.fn.line("$") do
			local line_text = vim.fn.getline(current_line)

			for i = 1, #line_text do
				local char = line_text:sub(i, i)
				if char == "{" then
					found_opening = true
					brace_count = brace_count + 1
				elseif char == "}" and found_opening then
					brace_count = brace_count - 1
					if brace_count == 0 then
						vim.fn.cursor(current_line, #line_text)
						break
					end
				end
			end
			if found_opening and brace_count == 0 then
				break
			end
			current_line = current_line + 1
		end

		-- Execute the tree-copy functionality
		require("tree-copy").copy_related_code()

		-- Get the contents of the default register
		local copied_content = vim.fn.getreg('"')

		-- Create a new buffer and paste the content
		vim.cmd("enew")
		vim.bo.filetype = "typescript"
		vim.cmd('put "')

		-- Get the pasted content
		local pasted_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local pasted_content = table.concat(pasted_lines, "\n")

		-- Check that the copied content includes expected references

		-- Should include import statements for dependencies used in grid function
		if not string.find(pasted_content, "import.*throttle.*debounce.*lodash") then
			error("Should include lodash imports")
		end

		-- Should include the GridConfig interface since it's referenced in grid function
		if not string.find(pasted_content, "interface GridConfig") then
			error("Should include GridConfig interface")
		end

		-- Should include the GridRenderer class since it's instantiated in grid function
		if not string.find(pasted_content, "class GridRenderer") then
			error("Should include GridRenderer class")
		end

		-- Should include the grid function itself
		if not string.find(pasted_content, "export function grid") then
			error("Should include the grid function")
		end

		-- Should include any type definitions used
		if
			not (
				string.find(pasted_content, "type CellPosition")
				or string.find(pasted_content, "interface.*CellPosition")
			)
		then
			error("Should include CellPosition type if referenced")
		end

		-- Verify that the copied content is substantial (not empty)
		if #copied_content <= 100 then
			error("Copied content should be substantial")
		end

		-- Check that we found multiple related code blocks
		local block_count = 0
		for block in string.gmatch(copied_content, "[^\n\n]+") do
			if string.len(string.gsub(block, "%s", "")) > 10 then
				block_count = block_count + 1
			end
		end

		if block_count < 3 then
			error(string.format("Should find at least 3 related code blocks, found %d", block_count))
		end
	end)

	if not success then
		test_passed = false
		error_message = err or "Unknown error"
	end

	print_test_result("Copy grid function and references", test_passed, error_message)
	return test_passed
end

local function test_handle_no_identifiers()
	print("\n=== Testing handle cases where no identifiers are found ===")

	setup_plugin()
	local test_passed = true
	local error_message = ""

	local success, err = pcall(function()
		-- Create a buffer with content that has no clear identifiers
		vim.cmd("enew")
		vim.bo.filetype = "typescript"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {
			"// Just a comment",
			"/* Another comment */",
			"",
		})

		-- Select the comment
		vim.cmd("normal! ggV")

		-- Try to copy
		local copy_success = pcall(function()
			require("tree-copy").copy_related_code()
		end)

		-- Should not crash
		if not copy_success then
			error("Should handle empty selections gracefully")
		end
	end)

	if not success then
		test_passed = false
		error_message = err or "Unknown error"
	end

	print_test_result("Handle no identifiers", test_passed, error_message)
	return test_passed
end

-- Main test runner
local function run_tree_copy_functionality_tests()
	print("=== Tree-Copy Functionality Test Suite ===")

	local test1_passed = test_copy_grid_function_and_references()
	local test2_passed = test_handle_no_identifiers()

	print("\n=== Test Suite Complete ===")

	local all_passed = test1_passed and test2_passed
	print_test_result("Overall Result", all_passed, "All functionality tests completed")

	return all_passed
end

-- Run the tests
run_tree_copy_functionality_tests()
