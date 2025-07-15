local M = {}

local function collect_identifiers_recursive(node, identifiers)
	local node_type = node:type()

	-- Extract main identifiers (variable names, function names, etc.)
	if node_type == "identifier" then
		local text = vim.treesitter.get_node_text(node, 0)
		identifiers[text] = true
	elseif node_type == "type_identifier" then
		local text = vim.treesitter.get_node_text(node, 0)
		identifiers[text] = true
	end
	-- Note: Removed property_identifier to avoid extracting property names
	-- from object literals, which causes too many matches

	for child in node:iter_children() do
		collect_identifiers_recursive(child, identifiers)
	end
end

function M.extract_identifiers(node)
	local identifiers = {}
	collect_identifiers_recursive(node, identifiers)

	local result = {}
	for identifier, _ in pairs(identifiers) do
		table.insert(result, identifier)
	end

	return result
end

local function is_related_node(node, identifiers)
	local node_type = node:type()

	-- Check import statements to see if they import any of our identifiers
	if node_type == "import_statement" then
		-- Check for namespace imports like "import * as fs from 'node:fs'"
		for child in node:iter_children() do
			if child:type() == "import_clause" then
				for grandchild in child:iter_children() do
					if grandchild:type() == "namespace_import" then
						for ggchild in grandchild:iter_children() do
							if ggchild:type() == "identifier" then
								local import_name = vim.treesitter.get_node_text(ggchild, 0)
								for _, identifier in ipairs(identifiers) do
									if import_name == identifier then
										return true
									end
								end
							end
						end
					elseif grandchild:type() == "named_imports" then
						-- Check for named imports like "import { readFile } from 'fs'"
						for ggchild in grandchild:iter_children() do
							if ggchild:type() == "import_specifier" then
								for gggchild in ggchild:iter_children() do
									if gggchild:type() == "identifier" then
										local import_name = vim.treesitter.get_node_text(gggchild, 0)
										for _, identifier in ipairs(identifiers) do
											if import_name == identifier then
												return true
											end
										end
									end
								end
							end
						end
					elseif grandchild:type() == "identifier" then
						-- Check for default imports like "import fs from 'fs'"
						local import_name = vim.treesitter.get_node_text(grandchild, 0)
						for _, identifier in ipairs(identifiers) do
							if import_name == identifier then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end

	-- For export statements, check what they're exporting
	if node_type == "export_statement" then
		for child in node:iter_children() do
			local child_type = child:type()
			
			-- Check if this is a declaration export that defines one of our identifiers
			if child_type == "interface_declaration" then
				local interface_name = nil
				for grandchild in child:iter_children() do
					if grandchild:type() == "type_identifier" then
						interface_name = vim.treesitter.get_node_text(grandchild, 0)
						break
					end
				end
				
				for _, identifier in ipairs(identifiers) do
					if interface_name == identifier then
						return true
					end
				end
			elseif child_type == "class_declaration" then
				local class_name = nil
				for grandchild in child:iter_children() do
					if grandchild:type() == "type_identifier" then
						class_name = vim.treesitter.get_node_text(grandchild, 0)
						break
					end
				end
				
				for _, identifier in ipairs(identifiers) do
					if class_name == identifier then
						return true
					end
				end
			elseif child_type == "function_declaration" then
				local function_name = nil
				for grandchild in child:iter_children() do
					if grandchild:type() == "identifier" then
						function_name = vim.treesitter.get_node_text(grandchild, 0)
						break
					end
				end
				
				for _, identifier in ipairs(identifiers) do
					if function_name == identifier then
						return true
					end
				end
			end
		end
		return false
	end

	-- For variable/const declarations, check if they declare one of our identifiers
	if node_type == "lexical_declaration" or node_type == "variable_declaration" then
		for child in node:iter_children() do
			if child:type() == "variable_declarator" then
				local var_name = nil
				local name_node = child:child(0)
				if name_node and name_node:type() == "identifier" then
					var_name = vim.treesitter.get_node_text(name_node, 0)
				end
				
				for _, identifier in ipairs(identifiers) do
					if var_name == identifier then
						return true
					end
				end
			end
		end
		return false
	end

	-- For interface declarations, check if they declare one of our identifiers
	if node_type == "interface_declaration" then
		for child in node:iter_children() do
			if child:type() == "type_identifier" then
				local interface_name = vim.treesitter.get_node_text(child, 0)
				for _, identifier in ipairs(identifiers) do
					if interface_name == identifier then
						return true
					end
				end
				break
			end
		end
		return false
	end

	-- For class declarations, check if they declare one of our identifiers
	if node_type == "class_declaration" then
		for child in node:iter_children() do
			if child:type() == "type_identifier" then
				local class_name = vim.treesitter.get_node_text(child, 0)
				for _, identifier in ipairs(identifiers) do
					if class_name == identifier then
						return true
					end
				end
				break
			end
		end
		return false
	end

	-- For function declarations, check if they declare one of our identifiers
	if node_type == "function_declaration" or node_type == "generator_function_declaration" then
		for child in node:iter_children() do
			if child:type() == "identifier" then
				local function_name = vim.treesitter.get_node_text(child, 0)
				for _, identifier in ipairs(identifiers) do
					if function_name == identifier then
						return true
					end
				end
				break
			end
		end
		return false
	end

	-- For type alias declarations, check if they declare one of our identifiers
	if node_type == "type_alias_declaration" then
		for child in node:iter_children() do
			if child:type() == "type_identifier" then
				local type_name = vim.treesitter.get_node_text(child, 0)
				for _, identifier in ipairs(identifiers) do
					if type_name == identifier then
						return true
					end
				end
				break
			end
		end
		return false
	end

	-- For enum declarations, check if they declare one of our identifiers
	if node_type == "enum_declaration" then
		for child in node:iter_children() do
			if child:type() == "identifier" then
				local enum_name = vim.treesitter.get_node_text(child, 0)
				for _, identifier in ipairs(identifiers) do
					if enum_name == identifier then
						return true
					end
				end
				break
			end
		end
		return false
	end

	return false
end

local function collect_related_nodes_recursive(node, identifiers, related_nodes)
	if is_related_node(node, identifiers) then
		table.insert(related_nodes, node)
		return
	end

	for child in node:iter_children() do
		collect_related_nodes_recursive(child, identifiers, related_nodes)
	end
end

function M.find_related_nodes(parser, identifiers)
	if #identifiers == 0 then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local related_nodes = {}
	local processed_identifiers = {}
	
	-- Keep track of identifiers we've already processed to avoid infinite loops
	local function mark_processed(identifier_list)
		for _, id in ipairs(identifier_list) do
			processed_identifiers[id] = true
		end
	end
	
	-- Get identifiers that haven't been processed yet
	local function get_unprocessed_identifiers(identifier_list)
		local unprocessed = {}
		for _, id in ipairs(identifier_list) do
			if not processed_identifiers[id] then
				table.insert(unprocessed, id)
			end
		end
		return unprocessed
	end

	-- Recursively find related nodes and their dependencies
	local function find_dependencies(current_identifiers)
		local unprocessed = get_unprocessed_identifiers(current_identifiers)
		if #unprocessed == 0 then
			return
		end
		
		mark_processed(unprocessed)
		
		-- Find nodes that declare these identifiers
		local current_nodes = {}
		collect_related_nodes_recursive(root, unprocessed, current_nodes)
		
		-- Add found nodes to our result
		for _, node in ipairs(current_nodes) do
			table.insert(related_nodes, node)
		end
		
		-- For each found node, extract identifiers it uses and find their dependencies
		for _, node in ipairs(current_nodes) do
			local used_identifiers = M.extract_identifiers(node)
			if #used_identifiers > 0 then
				find_dependencies(used_identifiers)
			end
		end
	end

	find_dependencies(identifiers)

	return related_nodes
end

return M
