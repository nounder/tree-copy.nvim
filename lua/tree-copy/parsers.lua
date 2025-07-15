local M = {}

local typescript = require("tree-copy.parsers.typescript")

local language_modules = {
	typescript = typescript,
	javascript = typescript,
	typescriptreact = typescript,
	javascriptreact = typescript,
}

function M.is_supported(filetype)
	return language_modules[filetype] ~= nil
end

function M.get_parser(filetype)
	if not M.is_supported(filetype) then
		return nil
	end

	local lang = filetype == "typescriptreact" and "tsx"
		or filetype == "javascriptreact" and "jsx"
		or filetype == "typescript" and "typescript"
		or "javascript"

	local ok, parser = pcall(vim.treesitter.get_parser, 0, lang)
	if not ok then
		return nil
	end

	return parser
end

function M.extract_identifiers(filetype, node)
	local module = language_modules[filetype]
	if not module then
		return {}
	end

	return module.extract_identifiers(node)
end

function M.find_related_nodes(filetype, parser, identifiers)
	local module = language_modules[filetype]
	if not module then
		return {}
	end

	return module.find_related_nodes(parser, identifiers)
end

return M
