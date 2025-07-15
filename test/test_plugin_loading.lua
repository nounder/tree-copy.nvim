-- LUA_PATH should be set to include ./lua/?.lua;./lua/?/init.lua for module discovery

local function test_plugin_loading()
	local ok, tree_copy = pcall(require, "tree-copy")
	if not ok then
		print("✗ FAILED: Could not require tree-copy module")
		os.exit(1)
	end

	local ok2, parsers = pcall(require, "tree-copy.parsers")
	if not ok2 then
		print("✗ FAILED: Could not require tree-copy.parsers module")
		os.exit(1)
	end

	if type(tree_copy.setup) ~= "function" then
		print("✗ FAILED: setup function not found")
		os.exit(1)
	end

	if type(tree_copy.copy_related_code) ~= "function" then
		print("✗ FAILED: copy_related_code function not found")
		os.exit(1)
	end

	if type(parsers.is_supported) ~= "function" then
		print("✗ FAILED: parsers.is_supported function not found")
		os.exit(1)
	end

	print("✓ PASSED: Plugin loading test")
	return true
end

local success = test_plugin_loading()
if not success then
	os.exit(1)
end
