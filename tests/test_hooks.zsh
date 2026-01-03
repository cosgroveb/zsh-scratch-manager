#!/usr/bin/env zsh
# Tests for auto-cleanup hooks

test_periodic_hook_registered() {
    # Source the plugin
    source "${PROJECT_DIR}/scratch-manager.plugin.zsh"

    # Check that PERIOD is set
    if [[ -z "$PERIOD" ]] || (( PERIOD <= 0 )); then
        echo "  PERIOD not set correctly"
        return 1
    fi

    # Check that periodic function exists
    if ! typeset -f periodic >/dev/null 2>&1; then
        echo "  periodic function not defined"
        return 1
    fi

    return 0
}
run_test "periodic hook is registered" test_periodic_hook_registered

test_zshexit_hook_registered() {
    source "${PROJECT_DIR}/scratch-manager.plugin.zsh"

    # Check that zshexit function exists or is in zshexit_functions
    if typeset -f zshexit >/dev/null 2>&1; then
        return 0
    fi

    if [[ -n "${zshexit_functions[(r)_scratch_zshexit]}" ]]; then
        return 0
    fi

    echo "  zshexit hook not registered"
    return 1
}
run_test "zshexit hook is registered" test_zshexit_hook_registered
