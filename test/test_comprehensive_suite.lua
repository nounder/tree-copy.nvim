local function print_test_result(test_name, passed, message)
	local status = passed and "PASS" or "FAIL"
	print(string.format("[%s] %s: %s", status, test_name, message or ""))
end

local function run_individual_test(test_name, test_file)
	print("Running: " .. test_name)
	local cmd = "cd "
		.. vim.fn.getcwd()
		.. " && LUA_PATH='./lua/?.lua;./lua/?/init.lua' nvim -l "
		.. test_file
		.. " 2>&1"
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	local success = handle:close()

	if success then
		print("✓ PASSED: " .. test_name)
		return true
	else
		print("✗ FAILED: " .. test_name)
		print("  Output: " .. result)
		return false
	end
end

local function run_comprehensive_test_suite()
	print("=== Tree-Copy.nvim Comprehensive Test Suite ===\n")
	print("Running individual test files...\n")

	local tests = {
		{ "Plugin Loading", "test/test_plugin_loading.lua" },
		{ "Parser Availability", "test/test_parser_availability.lua" },
		{ "Tree-sitter Parsing", "test/test_treesitter_parsing.lua" },
		{ "Visual Selection Detection", "test/test_visual_selection.lua" },
		{ "Node Selection", "test/test_node_selection.lua" },
		{ "Identifier Extraction", "test/test_identifier_extraction.lua" },
		{ "Related Node Finding", "test/test_related_node_finding.lua" },
		{ "Complete Copy Functionality", "test/test_complete_copy_functionality.lua" },
		{ "Filetype Support", "test/test_filetype_support.lua" },
		{ "Error Handling", "test/test_error_handling.lua" },
	}

	local tests_passed = 0
	local tests_total = #tests

	for _, test in ipairs(tests) do
		if run_individual_test(test[1], test[2]) then
			tests_passed = tests_passed + 1
		end
		print("")
	end

	-- Print results
	print("=== Test Results ===")
	print(string.format("Passed: %d/%d tests", tests_passed, tests_total))

	if tests_passed == tests_total then
		print("🎉 ALL TESTS PASSED! Tree-copy.nvim is working correctly.")
		return true
	else
		print("❌ Some tests failed. Please check the errors above.")
		return false
	end
end

-- Run the test suite
local success = run_comprehensive_test_suite()
if not success then
	vim.cmd("cquit 1") -- Exit with error code
end
