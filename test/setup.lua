#!/usr/bin/env nvim -l

-- Function to install a Tree-sitter parser
local function install_parser(parser)
    print("Installing " .. parser .. " parser...")
    vim.opt.rtp:append("~/.local/share/nvim/lazy/nvim-treesitter")
    require('nvim-treesitter.install').ensure_installed({ parser })
end

-- Install JavaScript parser
install_parser("javascript")

-- Install TypeScript parser
local success, err = pcall(install_parser, "typescript")
if not success then
    print("Note: TypeScript parser installation may have failed, using JavaScript for TypeScript files")
end

-- Verify TypeScript parser installation
print("Verifying TypeScript parser installation...")
local ts_success = pcall(function()
    vim.treesitter.language.require_language("typescript")
    print("✓ TypeScript parser verified")
end)

if not ts_success then
    print("⚠ TypeScript parser verification failed, tests may not work correctly")
end

print("Setup complete.")