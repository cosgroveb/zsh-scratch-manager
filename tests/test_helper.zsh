#!/usr/bin/env zsh
# Test helper functions for zsh-scratch-manager

# Test state
typeset -g TEST_PASSED=0
typeset -g TEST_FAILED=0
typeset -g TEST_CURRENT=""
typeset -g TEST_TMP_DIR=""

# Colors
typeset -g RED=$'\e[31m'
typeset -g GREEN=$'\e[32m'
typeset -g YELLOW=$'\e[33m'
typeset -g RESET=$'\e[0m'

# Setup test environment
test_setup() {
    TEST_TMP_DIR="$(mktemp -d)"
    export SCRATCH_DIR="${TEST_TMP_DIR}/scratch"
    export SCRATCH_CLEANUP_PERIOD=3600
    export SCRATCH_CLEANUP_AGE=3600
    export SCRATCH_DEFAULT_PREFIX=tmp
    mkdir -p "$SCRATCH_DIR"
}

# Teardown test environment
test_teardown() {
    if [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

# Run a single test
run_test() {
    local test_name="$1"
    local test_fn="$2"

    TEST_CURRENT="$test_name"

    test_setup

    if eval "$test_fn"; then
        echo "${GREEN}PASS${RESET}: $test_name"
        ((TEST_PASSED++))
    else
        echo "${RED}FAIL${RESET}: $test_name"
        ((TEST_FAILED++))
    fi

    test_teardown
}

# Assertions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Expected '$expected', got '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local msg="${3:-Did not expect '$unexpected'}"

    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local msg="${2:-Directory '$dir' should exist}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_directory_not_exists() {
    local dir="$1"
    local msg="${2:-Directory '$dir' should not exist}"

    if [[ ! -d "$dir" ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File '$file' should exist}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_success() {
    local msg="${1:-Command should succeed}"

    if [[ $? -eq 0 ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg (exit code: $?)"
        return 1
    fi
}

assert_failure() {
    local exit_code="$1"
    local msg="${2:-Command should fail}"

    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

assert_output_contains() {
    local output="$1"
    local expected="$2"
    local msg="${3:-Output should contain '$expected'}"

    if [[ "$output" == *"$expected"* ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        echo "  Output was: $output"
        return 1
    fi
}

assert_output_not_contains() {
    local output="$1"
    local unexpected="$2"
    local msg="${3:-Output should not contain '$unexpected'}"

    if [[ "$output" != *"$unexpected"* ]]; then
        return 0
    else
        echo "  ${RED}ASSERTION FAILED${RESET}: $msg"
        return 1
    fi
}

# Print test summary
test_summary() {
    echo ""
    echo "================================"
    echo "Tests: $((TEST_PASSED + TEST_FAILED))"
    echo "${GREEN}Passed${RESET}: $TEST_PASSED"
    echo "${RED}Failed${RESET}: $TEST_FAILED"
    echo "================================"

    if [[ $TEST_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}
