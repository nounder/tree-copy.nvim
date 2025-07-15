local M = {}

local parsers = require("tree-copy.parsers")

function M.setup()
	vim.keymap.set("v", "<leader>y", function()
		M.copy_related_code()
	end, { desc = "Copy related code using tree-sitter" })
end

function M.copy_related_code()
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype

	if not parsers.is_supported(filetype) then
		vim.notify("Filetype '" .. filetype .. "' is not supported", vim.log.levels.WARN)
		return
	end

	local parser = parsers.get_parser(filetype)
	if not parser then
		vim.notify("Failed to get parser for " .. filetype, vim.log.levels.ERROR)
		return
	end

	local start_row, start_col, end_row, end_col = M.get_visual_selection()
	local selected_node = M.get_node_at_selection(parser, start_row, start_col, end_row, end_col)

	if not selected_node then
		vim.notify("No tree-sitter node found in selection", vim.log.levels.WARN)
		return
	end

	local identifiers = parsers.extract_identifiers(filetype, selected_node)
	if #identifiers == 0 then
		vim.notify("No identifiers found in selection", vim.log.levels.WARN)
		return
	end

	local related_nodes = parsers.find_related_nodes(filetype, parser, identifiers)
	local related_text = M.get_text_from_nodes(bufnr, related_nodes)

	local concatenated = table.concat(related_text, "\n\n")
	vim.fn.setreg('"', concatenated)
	vim.fn.setreg("0", concatenated) -- Also set yank register
	vim.notify("Copied " .. #related_nodes .. " related code blocks to register", vim.log.levels.INFO)
end

function M.get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Handle case where visual selection markers are not set
	if start_pos[2] == 0 or end_pos[2] == 0 then
		-- Use current line if no visual selection
		local current_line = vim.fn.line(".")
		return current_line - 1, 0, current_line - 1, vim.fn.col("$") - 1
	end

	return start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3] - 1
end

function M.get_node_at_selection(parser, start_row, start_col, end_row, end_col)
	local tree = parser:parse()[1]
	local root = tree:root()

	local function find_smallest_containing_node(node)
		local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

		-- Check if node contains the selection
		local contains_start = (node_start_row < start_row)
			or (node_start_row == start_row and node_start_col <= start_col)
		local contains_end = (node_end_row > end_row) or (node_end_row == end_row and node_end_col >= end_col)

		if contains_start and contains_end then
			-- Try to find a smaller containing node among children
			for child in node:iter_children() do
				local smaller = find_smallest_containing_node(child)
				if smaller then
					return smaller
				end
			end

			-- If no smaller node found, return this node
			return node
		end

		return nil
	end

	local result = find_smallest_containing_node(root)

	-- If no containing node found, try to find any overlapping node
	if not result then
		local function find_overlapping_node(node)
			local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

			-- Check if there's any overlap between node and selection
			local overlaps = not (
				node_end_row < start_row
				or node_start_row > end_row
				or (node_end_row == start_row and node_end_col < start_col)
				or (node_start_row == end_row and node_start_col > end_col)
			)

			if overlaps then
				-- Try children first for more specific nodes
				for child in node:iter_children() do
					local child_result = find_overlapping_node(child)
					if child_result then
						return child_result
					end
				end

				-- Return this node if it's meaningful (not just punctuation)
				local node_type = node:type()
				if not node_type:match("^[{}();,]$") and node_type ~= "ERROR" then
					return node
				end
			end

			return nil
		end

		result = find_overlapping_node(root)
	end

	return result
end

function M.get_text_from_nodes(bufnr, nodes)
	local result = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for _, node in ipairs(nodes) do
		local start_row, start_col, end_row, end_col = node:range()
		local node_text = {}

		if start_row == end_row then
			table.insert(node_text, string.sub(lines[start_row + 1], start_col + 1, end_col))
		else
			table.insert(node_text, string.sub(lines[start_row + 1], start_col + 1))

			for row = start_row + 1, end_row - 1 do
				table.insert(node_text, lines[row + 1])
			end

			table.insert(node_text, string.sub(lines[end_row + 1], 1, end_col))
		end

		table.insert(result, table.concat(node_text, "\n"))
	end

	return result
end

return M
