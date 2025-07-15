#!/usr/bin/env nvim -l

local function test_filetype_support()
	print("=== Testing Filetype Support ===")

	local parsers = require("tree-copy.parsers")

	if not parsers.is_supported("javascript") then
		print("✗ FAILED: JavaScript should be supported")
		os.exit(1)
	end

	if not parsers.is_supported("typescript") then
		print("✗ FAILED: TypeScript should be supported")
		os.exit(1)
	end

	if not parsers.is_supported("typescriptreact") then
		print("✗ FAILED: TSX should be supported")
		os.exit(1)
	end

	if not parsers.is_supported("javascriptreact") then
		print("✗ FAILED: JSX should be supported")
		os.exit(1)
	end

	if parsers.is_supported("python") then
		print("✗ FAILED: Python should not be supported")
		os.exit(1)
	end

	print("✓ PASSED: Filetype support test")
	return true
end

require("tree-copy").setup()
local success = test_filetype_support()
if not success then
	os.exit(1)
end