Rework tests in test/ directory so its logical test has its own file and is executed with `#!/usr/bin/env nvim -l` just like @test_manual_sequence.lua

Try to execute all test logic on a seperate nvim instance unnless it makes sense to run it in a shell, is such case test should have bash shebang, and end with .sh ext. when any assertion fails it should exit with 1 (for both lua and shell)
