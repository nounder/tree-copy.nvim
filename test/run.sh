#!/bin/bash

# Test runner script for tree-copy.nvim
# Usage: ./test.sh [test_file1] [test_file2] ...
# If no arguments provided, runs all tests matching test/test_*
# Executes individual test files based on their shebang

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Tree-Copy.nvim Test Suite ==="
echo "Project root: $PROJECT_ROOT"
echo

# Change to project root
cd "$PROJECT_ROOT"

# Ensure treesitter parsers are available
echo "Ensuring treesitter grammars are available..."
echo "Installing JavaScript parser..."
nvim --headless -c "set rtp+=~/.local/share/nvim/lazy/nvim-treesitter" -c "TSInstall! javascript" -c "qall"

echo "Installing TypeScript parser..."
nvim --headless -c "set rtp+=~/.local/share/nvim/lazy/nvim-treesitter" -c "TSInstall! typescript" -c "qall" 2>/dev/null || {
    echo "Note: TypeScript parser installation may have failed, using JavaScript for TypeScript files"
}

# Verify TypeScript parser is properly installed
echo "Verifying TypeScript parser installation..."
if nvim --headless -c "set rtp+=~/.local/share/nvim/lazy/nvim-treesitter" -c "lua if vim.treesitter.language.require_language('typescript') then print('TypeScript parser verified') else error('TypeScript parser not found') end" -c "qall" 2>/dev/null; then
    echo "✓ TypeScript parser verified"
else
    echo "⚠ TypeScript parser verification failed, tests may not work correctly"
fi

echo "Parser setup complete."
echo

# Array to track test results
declare -a test_results
passed=0
failed=0

# Function to run a test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file")
    
    echo "Running: $test_name"
    
    if [[ -x "$test_file" ]]; then
        # Execute based on shebang
        "$test_file"
        if [ $? -eq 0 ]; then
            echo "✓ PASSED: $test_name"
            test_results+=("✓ $test_name")
            ((passed++))
        else
            echo "✗ FAILED: $test_name (exit code: $?)"
            test_results+=("✗ $test_name")
            ((failed++))
        fi
    else
        # Lua test with nvim -l
        # Set LUA_PATH to include plugin module paths
        LUA_PATH="$PROJECT_ROOT/lua/?.lua;$PROJECT_ROOT/lua/?/init.lua;"
package_path="$PROJECT_ROOT/lua/?.lua;$PROJECT_ROOT/lua/?/init.lua;"
export LUA_PATH
export NVIM_LUA_PATH="$LUA_PATH"
        if nvim --headless -c "lua print('LUA_PATH:', package.path)" -c "qall" && nvim --headless -c "lua package.path='$LUA_PATH'..package.path; print('LUA_PATH:', package.path)" -l "$test_file"; then
            echo "✓ PASSED: $test_name"
            test_results+=("✓ $test_name")
            ((passed++))
        else
            echo "✗ FAILED: $test_name (exit code: $?)"
            test_results+=("✗ $test_name")
            ((failed++))
        fi
    fi
    echo
}

# Find and run test files
if [[ $# -eq 0 ]]; then
    # No arguments provided - run all tests
    echo "Finding all test files..."
    test_files=$(find test/ -name "test_*" | sort)
    
    if [[ -z "$test_files" ]]; then
        echo "No test files found!"
        exit 1
    fi
else
    # Arguments provided - run only specified test files
    echo "Running specified test files..."
    
    # Validate that all provided files exist
    for test_file in "$@"; do
        if [[ ! -f "$test_file" ]]; then
            echo "Error: Test file '$test_file' not found!"
            exit 1
        fi
    done
    
    test_files="$*"
fi

for test_file in $test_files; do
    run_test "$test_file"
done

# Summary
echo "=== Test Summary ==="
for result in "${test_results[@]}"; do
    echo "$result"
done

echo
echo "Total: $((passed + failed)) tests"
echo "Passed: $passed"
echo "Failed: $failed"

if [[ $failed -eq 0 ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed."
    exit 1
fi

