local function print_test_result(test_name, passed, message)
	local status = passed and "PASS" or "FAIL"
	print(string.format("[%s] %s: %s", status, test_name, message or ""))
end

local function setup_plugin()
	-- Plugin should be available via LUA_PATH when test is run
	-- No setup() call needed for basic functionality
end

local function test_copy_default_grid_config()
	print("\n=== Testing copy DEFAULT_GRID_CONFIG constant and its type ===")

	setup_plugin()
	local test_passed = true
	local error_message = ""
	local success, err = pcall(function()
		local fixture_path = vim.fn.fnamemodify("./test/fixture_single_module.ts", ":p")

		-- Open the fixture file
		print("Opening fixture file:", fixture_path)
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

		-- Navigate to DEFAULT_GRID_CONFIG (line 29)
		local line_num = vim.fn.search("const DEFAULT_GRID_CONFIG: GridConfig = {")
		if line_num == 0 then
			error("Could not find DEFAULT_GRID_CONFIG in fixture")
		end

		print("Found DEFAULT_GRID_CONFIG at line:", line_num)
		vim.fn.cursor(line_num, 1)

		-- Visual select the entire DEFAULT_GRID_CONFIG constant
		-- Start visual mode at beginning of line
		vim.cmd("normal! 0V")

		-- Move down to select all lines of the constant (lines 29-33)
		vim.cmd("normal! 4j")

		-- Verify we have the right selection
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		print(string.format("Visual selection from line %d to %d", start_line, end_line))

		-- Execute the tree-copy functionality with <leader>y
		require("tree-copy").copy_related_code()

		-- Get the contents of the default register
		local copied_content = vim.fn.getreg('"')
		print("Copied content length:", #copied_content)

		-- Create a new empty buffer and paste
		vim.cmd("enew")
		vim.bo.filetype = "typescript"
		vim.cmd('put "')

		-- Get the pasted content
		local pasted_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local pasted_content = table.concat(pasted_lines, "\n")

		print("\n=== Pasted Content ===")
		print(pasted_content)
		print("=== End Pasted Content ===\n")

		-- Define expected content
		local expected_content = [[export interface GridConfig {
  rows: number;
  cols: number;
  cellSize: number;
}

const DEFAULT_GRID_CONFIG: GridConfig = {
  rows: 10,
  cols: 10,
  cellSize: 32
};]]

		-- Remove any leading/trailing whitespace and normalize line endings
		local normalized_pasted = string.gsub(string.gsub(pasted_content, "^%s+", ""), "%s+$", "")
		local normalized_expected = string.gsub(string.gsub(expected_content, "^%s+", ""), "%s+$", "")

		-- Compare the content
		if normalized_pasted ~= normalized_expected then
			error(
				"Pasted content does not match expected content.\nExpected:\n"
					.. normalized_expected
					.. "\n\nActual:\n"
					.. normalized_pasted
			)
		end
	end)

	if not success then
		test_passed = false
		error_message = err or "Unknown error"
	end

	print_test_result("Copy DEFAULT_GRID_CONFIG and its type", test_passed, error_message)
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

local function test_copy_main_function()
	print("\n=== Testing copy main function and related greet function ===")

	setup_plugin()
	local test_passed = true
	local error_message = ""
	local success, err = pcall(function()
		local fixture_path = vim.fn.fnamemodify("./test/fixture_single_module.ts", ":p")

		-- Open the fixture file
		print("Opening fixture file:", fixture_path)
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

		-- Navigate to main function (line 40)
		local line_num = vim.fn.search("export function main()")
		if line_num == 0 then
			error("Could not find main function in fixture")
		end

		print("Found main function at line:", line_num)

		-- Move to the line with "greet()" and select the word "greet"
		vim.fn.cursor(line_num + 1, 1)
		local greet_line = vim.fn.search("greet()")
		print("Found greet() at line:", greet_line)

		-- Position cursor on the word "greet"
		vim.fn.cursor(greet_line, 3)

		-- Start visual mode and select the word
		vim.cmd("normal! v")
		vim.cmd("normal! iw")

		-- Alternative: Let's just manually set the visual selection marks
		vim.fn.setpos("'<", { 0, greet_line, 3, 0 })
		vim.fn.setpos("'>", { 0, greet_line, 7, 0 })

		-- Verify we have the right selection
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		local start_col = vim.fn.col("'<")
		local end_col = vim.fn.col("'>")
		print(
			string.format(
				"Visual selection from line %d col %d to line %d col %d",
				start_line,
				start_col,
				end_line,
				end_col
			)
		)

		-- Show what text is selected
		local selected_text = vim.fn.getline(start_line):sub(start_col, end_col)
		print("Selected text:", selected_text)

		-- Execute the tree-copy functionality
		require("tree-copy").copy_related_code()

		-- Get the contents of the default register
		local copied_content = vim.fn.getreg('"')
		print("Copied content length:", #copied_content)

		-- Create a new empty buffer and paste
		vim.cmd("enew")
		vim.bo.filetype = "typescript"
		vim.cmd('put "')

		-- Get the pasted content
		local pasted_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local pasted_content = table.concat(pasted_lines, "\n")

		print("\n=== Pasted Content ===")
		print(pasted_content)
		print("=== End Pasted Content ===\n")

		-- Expected content - should have main, greet functions and message variable
		local expected_content = [[export function main() {
  greet()
}

function greet() {
  console.log(message)
}

const message = "Welcome";]]

		-- Remove any leading/trailing whitespace and normalize line endings
		local normalized_pasted = string.gsub(string.gsub(pasted_content, "^%s+", ""), "%s+$", "")
		local normalized_expected = string.gsub(string.gsub(expected_content, "^%s+", ""), "%s+$", "")

		-- Compare the entire content as a single string
		if normalized_pasted ~= normalized_expected then
			error(
				"Pasted content does not match expected content.\nExpected:\n"
					.. normalized_expected
					.. "\n\nActual:\n"
					.. normalized_pasted
			)
		end
	end)

	if not success then
		test_passed = false
		error_message = err or "Unknown error"
	end

	print_test_result("Copy main function and related greet function", test_passed, error_message)
	return test_passed
end

local function test_copy_readconfig_with_imports()
	print("\n=== Testing copy readConfig function with fs imports ===")

	setup_plugin()
	local test_passed = true
	local error_message = ""
	local success, err = pcall(function()
		local fixture_path = vim.fn.fnamemodify("./test/fixture_single_module.ts", ":p")

		-- Open the fixture file
		print("Opening fixture file:", fixture_path)
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

		-- Navigate to readConfig function
		local line_num = vim.fn.search("export function readConfig()")
		if line_num == 0 then
			error("Could not find readConfig function in fixture")
		end

		print("Found readConfig function at line:", line_num)
		vim.fn.cursor(line_num, 1)

		-- Visual select the entire readConfig function
		vim.cmd("normal! 0V")
		vim.cmd("normal! 2j")

		-- Verify we have the right selection
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		print(string.format("Visual selection from line %d to %d", start_line, end_line))

		-- Execute the tree-copy functionality
		require("tree-copy").copy_related_code()

		-- Get the contents of the default register
		local copied_content = vim.fn.getreg('"')
		print("Copied content length:", #copied_content)

		-- Create a new empty buffer and paste
		vim.cmd("enew")
		vim.bo.filetype = "typescript"
		vim.cmd('put "')

		-- Get the pasted content
		local pasted_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local pasted_content = table.concat(pasted_lines, "\n")

		print("\n=== Pasted Content ===")
		print(pasted_content)
		print("=== End Pasted Content ===\n")

		-- Expected content - should include fs import and readConfig function
		-- Note: The leading newline is expected because vim's 'put' command adds it
		local expected_content = "\nimport * as fs from \"node:fs\"\n\nexport function readConfig() {\n  return fs.readFileSync(\"config.json\")\n}"

		-- Compare the raw buffer content directly with literal string
		if pasted_content ~= expected_content then
			error(
				"Buffer content does not match expected literal string.\nExpected:\n"
					.. vim.inspect(expected_content)
					.. "\n\nActual:\n"
					.. vim.inspect(pasted_content)
			)
		end
	end)

	if not success then
		test_passed = false
		error_message = err or "Unknown error"
	end

	print_test_result("Copy readConfig function with fs imports", test_passed, error_message)
	return test_passed
end

-- Main test runner
local function run_tree_copy_functionality_tests()
	print("=== Tree-Copy Functionality Test Suite ===")

	local test1_passed = test_copy_default_grid_config()
	local test2_passed = test_handle_no_identifiers()
	local test3_passed = test_copy_main_function()
	local test4_passed = test_copy_readconfig_with_imports()

	print("\n=== Test Suite Complete ===")

	local all_passed = test1_passed and test2_passed and test3_passed and test4_passed
	print_test_result("Overall Result", all_passed, "All functionality tests completed")

	return all_passed
end

-- Run the tests
run_tree_copy_functionality_tests()
