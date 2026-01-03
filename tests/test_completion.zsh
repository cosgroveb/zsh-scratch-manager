#!/usr/bin/env zsh
# Tests for tab completion

test_completion_function_exists() {
    # The _scratch function should be loadable
    if ! autoload -Uz +X _scratch 2>/dev/null; then
        echo "  _scratch completion function not found"
        return 1
    fi
    return 0
}
run_test "completion function is autoloadable" test_completion_function_exists

test_completion_defines_arguments() {
    autoload -Uz +X _scratch 2>/dev/null

    # Check that the function has content
    local func_def
    func_def=$(whence -f _scratch 2>/dev/null)

    if [[ -z "$func_def" ]]; then
        echo "  _scratch function is empty"
        return 1
    fi

    if [[ "$func_def" != *"_arguments"* && "$func_def" != *"compadd"* ]]; then
        echo "  _scratch doesn't use _arguments or compadd"
        return 1
    fi

    return 0
}
run_test "completion uses _arguments or compadd" test_completion_defines_arguments
