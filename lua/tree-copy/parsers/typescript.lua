local M = {}

local function collect_identifiers_recursive(node, identifiers)
	local node_type = node:type()

	if node_type == "identifier" then
		local text = vim.treesitter.get_node_text(node, 0)
		identifiers[text] = true
	elseif node_type == "property_identifier" then
		local text = vim.treesitter.get_node_text(node, 0)
		identifiers[text] = true
	elseif node_type == "type_identifier" then
		local text = vim.treesitter.get_node_text(node, 0)
		identifiers[text] = true
	end

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

	local related_types = {
		"import_statement",
		"import_clause",
		"namespace_import",
		"named_imports",
		"import_specifier",
		"variable_declaration",
		"lexical_declaration",
		"function_declaration",
		"generator_function_declaration",
		"class_declaration",
		"interface_declaration",
		"type_alias_declaration",
		"enum_declaration",
		"module_declaration",
		"export_statement",
		"export_clause",
		"named_exports",
		"export_specifier",
	}

	local is_target_type = false
	for _, target_type in ipairs(related_types) do
		if node_type == target_type then
			is_target_type = true
			break
		end
	end

	if not is_target_type then
		return false
	end

	local node_text = vim.treesitter.get_node_text(node, 0)
	for _, identifier in ipairs(identifiers) do
		if string.find(node_text, identifier, 1, true) then
			return true
		end
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

	collect_related_nodes_recursive(root, identifiers, related_nodes)

	return related_nodes
end

return M
