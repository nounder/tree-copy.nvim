-- Test utilities for tree-copy plugin
local M = {}

-- Ensure tree-sitter parser is ready for testing
-- This is a test-only utility and should not be used in production code
function M.ensure_treesitter_ready(bufnr, filetype)
	bufnr = bufnr or 0

	-- First, try immediate check (works 90% of the time)
	local parser = vim.treesitter.get_parser(bufnr, filetype)
	if parser then
		local success, trees = pcall(parser.parse, parser)
		if success and trees and #trees > 0 then
			return true -- Ready immediately
		end
	end

	-- Only if immediate check fails, use minimal wait
	local ready = false
	vim.wait(50, function() -- Very short: 50ms max
		parser = vim.treesitter.get_parser(bufnr, filetype)
		if parser then
			local success, trees = pcall(parser.parse, parser)
			if success and trees and #trees > 0 then
				ready = true
				return true
			end
		end
		return false
	end, 5) -- Check every 5ms

	return ready
end

return M
