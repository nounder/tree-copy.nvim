#!/usr/bin/env nvim -l

-- Test script that executes the exact manual sequence
local function test_manual_sequence()
	print("=== Testing Manual Sequence ===")

	-- Add lua path
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	-- Load the plugin
	require("tree-copy").setup()

	-- Open the fixture file
	vim.cmd("edit test/fixture_single_module.ts")
	vim.bo.filetype = "typescript"
	print("✓ Opened test/fixture_single_module.ts")

	-- Search for default_grid (case insensitive)
	vim.cmd("/default_grid")
	print("✓ Searched for default_grid, cursor at line:", vim.fn.line("."))

	-- Enter visual line mode and select 4 lines down
	vim.cmd("normal! V4j")
	print("✓ Selected 5 lines starting from DEFAULT_GRID_CONFIG")

	-- Get current mode to verify we're in visual mode
	local mode_before = vim.fn.mode()
	print("Mode before <space>Y:", mode_before)

	-- Execute <space>Y (assuming <leader> is space and Y is mapped to super yank)
	-- First check if we're in visual mode
	if mode_before:match("^[vV]") then
		-- Map space+Y to our copy function for this test
		vim.keymap.set("v", "<space>Y", function()
			require("tree-copy").copy_related_code()
		end, { desc = "Test super yank" })

		-- Execute the mapping
		vim.cmd("normal! \\<space>Y")
		print("✓ Executed <space>Y")
	else
		print("✗ Not in visual mode, mode was:", mode_before)
		return false
	end

	-- Check mode after operation
	local mode_after = vim.fn.mode()
	print("Mode after <space>Y:", mode_after)

	-- Verify we're back to normal mode
	local back_to_normal = mode_after == "n"
	print("✓ Back to normal mode:", back_to_normal and "YES" or "NO")

	-- Get the copied content from both registers
	local unnamed_reg = vim.fn.getreg('"')
	local yank_reg = vim.fn.getreg("0")

	print("\n=== Register Contents ===")
	print('Unnamed register ("')
	print("Length:", #unnamed_reg)
	print("Content preview:", string.sub(unnamed_reg, 1, 100) .. (#unnamed_reg > 100 and "..." or ""))

	print("\nYank register (0)")
	print("Length:", #yank_reg)
	print("Content preview:", string.sub(yank_reg, 1, 100) .. (#yank_reg > 100 and "..." or ""))

	-- Check if content looks correct
	local has_default_config = string.find(unnamed_reg, "DEFAULT_GRID_CONFIG")
	local has_grid_config = string.find(unnamed_reg, "GridConfig")

	print("\n=== Content Analysis ===")
	print("Contains DEFAULT_GRID_CONFIG:", has_default_config and "YES" or "NO")
	print("Contains GridConfig:", has_grid_config and "YES" or "NO")

	-- Test complete
	print("\n=== Test Summary ===")
	print("Sequence executed successfully:", back_to_normal and "YES" or "NO")
	print("Content seems correct:", (has_default_config and has_grid_config) and "YES" or "NO")

	return back_to_normal and has_default_config and has_grid_config
end

-- Run the test
local success = test_manual_sequence()
print("\n=== RESULT ===")
print(success and "✓ SUCCESS" or "✗ FAILED")
