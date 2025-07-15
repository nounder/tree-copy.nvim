local function test_parser_availability()
	print("=== Testing Parser Availability ===")

	local ok, parser = pcall(vim.treesitter.get_parser, 0, "javascript")
	if not ok then
		print("✗ FAILED: JavaScript parser not available: " .. tostring(parser))
		os.exit(1)
	end

	local parsers = require("tree-copy.parsers")
	if not parsers.is_supported("javascript") then
		print("✗ FAILED: JavaScript not supported by plugin")
		os.exit(1)
	end

	local plugin_parser = parsers.get_parser("javascript")
	if plugin_parser == nil then
		print("✗ FAILED: Plugin failed to get JavaScript parser")
		os.exit(1)
	end

	print("✓ PASSED: Parser availability test")
	return true
end

require("tree-copy").setup()
local success = test_parser_availability()
if not success then
	os.exit(1)
end
