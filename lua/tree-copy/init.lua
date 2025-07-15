local M = {}

local parsers = require("tree-copy.parsers")

function M.setup() end

-- Main function: copies the selected code and all its dependencies
function M.copy_related_code(start_pos, end_pos)
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

	-- Determine selection bounds: use provided positions or detect from visual mode
	local start_row, start_col, end_row, end_col
	if start_pos and end_pos then
		start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
		end_row, end_col = end_pos[2] - 1, end_pos[3] - 1

		if start_row > end_row or (start_row == end_row and start_col > end_col) then
			start_row, end_row = end_row, start_row
			start_col, end_col = end_col, start_col
		end
	else
		start_row, start_col, end_row, end_col = M.get_visual_selection()
	end

	print("Visual Selection:", start_row, start_col, end_row, end_col)
	local selected_node = M.get_node_at_selection(parser, start_row, start_col, end_row, end_col)
	print("Selected Node:", selected_node and selected_node:type() or "nil")

	if not selected_node then
		vim.notify("No tree-sitter node found in selection", vim.log.levels.WARN)
		return
	end

	local identifiers = parsers.extract_identifiers(filetype, selected_node)
	print("Extracted Identifiers:", vim.inspect(identifiers))
	if #identifiers == 0 then
		vim.notify("No identifiers found in selection", vim.log.levels.WARN)
		return
	end

	local related_nodes = parsers.find_related_nodes(filetype, parser, identifiers)

	-- Include the containing function/export when selecting within a function body
	local containing_function = M.find_containing_function(selected_node)
	if containing_function then
		-- Avoid duplicates by checking if already in related nodes
		local already_added = false
		for _, existing_node in ipairs(related_nodes) do
			if existing_node == containing_function then
				already_added = true
				break
			end
		end
		if not already_added then
			table.insert(related_nodes, 1, containing_function)
		end
	end

	print("Related Nodes:", vim.inspect(related_nodes))
	for _, node in ipairs(related_nodes) do
		print("Node Type:", node:type(), "Node Text:", vim.treesitter.get_node_text(node, 0))
	end
	local related_text = M.get_text_from_nodes(bufnr, related_nodes)

	local concatenated = table.concat(related_text, "\n\n")
	-- Set register with linewise type to match default yank behavior
	vim.fn.setreg('"', concatenated, "l")
	vim.fn.setreg("0", concatenated, "l") -- Also set yank register
	vim.fn.setreg("+", concatenated, "l") -- Also set system clipboard
	vim.notify("Copied " .. #related_nodes .. " related code blocks to register", vim.log.levels.INFO)
end

-- Helper function to find the containing function or export statement
function M.find_containing_function(node)
	local current = node
	local found_function = nil

	while current do
		local node_type = current:type()
		if node_type == "export_statement" then
			-- Prefer export statements over plain function declarations
			return current
		elseif
			node_type == "function_declaration"
			or node_type == "generator_function_declaration"
			or node_type == "lexical_declaration"
			or node_type == "variable_declaration"
		then
			-- Store the first function we find, but keep looking for export statements
			if not found_function then
				found_function = current
			end
		end
		current = current:parent()
	end

	return found_function
end

function M.get_visual_selection()
	local mode = vim.fn.mode()
	local start_pos, end_pos
	
	if mode == "v" or mode == "V" or mode == "\22" then -- \22 is visual block mode
		-- Active visual mode: get current selection bounds
		start_pos = vim.fn.getpos("v") -- Start of current visual selection
		end_pos = vim.fn.getpos(".") -- Current cursor position (end of selection)
	else
		-- Not in visual mode: use the last visual selection markers
		start_pos = vim.fn.getpos("'<")
		end_pos = vim.fn.getpos("'>")
	end

	-- Fallback to current line if no visual selection markers exist
	if start_pos[2] == 0 or end_pos[2] == 0 then
		local current_line = vim.fn.line(".")
		return current_line - 1, 0, current_line - 1, vim.fn.col("$") - 1
	end

	-- Convert to 0-based indexing and ensure proper ordering
	local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_row, end_col = end_pos[2] - 1, end_pos[3] - 1

	if start_row > end_row or (start_row == end_row and start_col > end_col) then
		start_row, end_row = end_row, start_row
		start_col, end_col = end_col, start_col
	end

	return start_row, start_col, end_row, end_col
end

function M.get_node_at_selection(parser, start_row, start_col, end_row, end_col)
	local tree = parser:parse()[1]
	local root = tree:root()

	-- Find the smallest tree-sitter node that completely contains the selection
	local function find_smallest_containing_node(node)
		local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

		-- Check if this node completely contains the user's selection
		local contains_start = (node_start_row < start_row)
			or (node_start_row == start_row and node_start_col <= start_col)
		local contains_end = (node_end_row > end_row) or (node_end_row == end_row and node_end_col >= end_col)

		if contains_start and contains_end then
			-- Recursively check children to find the most specific containing node
			for child in node:iter_children() do
				local smaller = find_smallest_containing_node(child)
				if smaller then
					return smaller
				end
			end

			-- No child contains the selection, so this is the smallest containing node
			return node
		end

		return nil
	end

	local result = find_smallest_containing_node(root)
	
	-- Reject root/program nodes to prevent copying entire file when selecting empty lines
	if result and (result == root or result:type() == "program") then
		result = nil
	end

	-- If no containing node found, look for nodes that overlap with the selection
	if not result then
		-- Look for nodes that have any overlap with the selection (partial matches)
		local function find_overlapping_node(node)
			local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

			-- Check if node and selection have any overlap using inverse logic
			local overlaps = not (
				node_end_row < start_row
				or node_start_row > end_row
				or (node_end_row == start_row and node_end_col < start_col)
				or (node_start_row == end_row and node_start_col > end_col)
			)

			if overlaps then
				-- Prefer more specific child nodes over parent nodes
				for child in node:iter_children() do
					local child_result = find_overlapping_node(child)
					if child_result then
						return child_result
					end
				end

				-- Only accept meaningful declaration nodes, not keywords or punctuation
				local node_type = node:type()
				local meaningful_types = {
					"function_declaration",
					"export_statement", 
					"class_declaration",
					"interface_declaration",
					"lexical_declaration",
					"variable_declaration",
					"type_alias_declaration",
					"enum_declaration"
				}
				
				local is_meaningful = false
				for _, meaningful_type in ipairs(meaningful_types) do
					if node_type == meaningful_type then
						is_meaningful = true
						break
					end
				end
				
				if is_meaningful and node ~= root and node_type ~= "program" then
					return node
				end
			end

			return nil
		end

		result = find_overlapping_node(root)
	end
	
	-- Last resort: find the nearest meaningful declaration when selecting empty space
	if not result then
		local function find_nearest_declaration(node, target_row)
			local best_node = nil
			local best_distance = math.huge
			
			local function check_node(n)
				local node_type = n:type()
				if node_type == "function_declaration" or 
				   node_type == "export_statement" or
				   node_type == "class_declaration" or
				   node_type == "interface_declaration" or
				   node_type == "lexical_declaration" or
				   node_type == "variable_declaration" then
					local start_row, _, end_row, _ = n:range()
					local distance = math.min(math.abs(start_row - target_row), math.abs(end_row - target_row))
					if distance < best_distance then
						best_distance = distance
						best_node = n
					end
				end
				
				for child in n:iter_children() do
					check_node(child)
				end
			end
			
			check_node(node)
			return best_node
		end
		
		-- Only use nearby declarations (within 3 lines) to avoid unrelated matches
		local nearest = find_nearest_declaration(root, start_row)
		if nearest then
			local start_row_nearest, _, end_row_nearest, _ = nearest:range()
			local distance = math.min(math.abs(start_row_nearest - start_row), math.abs(end_row_nearest - start_row))
			if distance <= 3 then
				result = nearest
			end
		end
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
