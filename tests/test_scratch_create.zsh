#!/usr/bin/env zsh
# Tests for scratch directory creation

test_creates_scratch_directory() {
    local output
    output=$(_scratch_create "test" 2>&1)
    local exit_code=$?

    assert_success || return 1
    assert_output_contains "$output" "$SCRATCH_DIR/test." || return 1

    # Verify directory was created
    local created_dir
    created_dir=$(echo "$output" | tail -1)
    assert_directory_exists "$created_dir" || return 1
}
run_test "creates scratch directory with prefix" test_creates_scratch_directory

test_creates_scratch_directory_default_prefix() {
    local output
    output=$(_scratch_create "" 2>&1)

    assert_output_contains "$output" "$SCRATCH_DIR/tmp." || return 1
}
run_test "uses default prefix when none provided" test_creates_scratch_directory_default_prefix

test_creates_base_directory_if_missing() {
    rm -rf "$SCRATCH_DIR"

    local output
    output=$(_scratch_create "test" 2>&1)

    assert_directory_exists "$SCRATCH_DIR" || return 1
}
run_test "creates base directory if missing" test_creates_base_directory_if_missing

test_creates_unique_directories() {
    local dir1 dir2
    dir1=$(_scratch_create "test" 2>&1 | tail -1)
    dir2=$(_scratch_create "test" 2>&1 | tail -1)

    assert_not_equals "$dir1" "$dir2" "Each scratch dir should be unique" || return 1
}
run_test "creates unique directories each time" test_creates_unique_directories

test_scratch_changes_to_directory() {
    local original_dir="$PWD"

    # Run scratch in a subshell and capture the directory
    local scratch_dir
    scratch_dir=$(scratch "mytest" 2>&1 | grep "^${SCRATCH_DIR}")

    assert_directory_exists "$scratch_dir" "Scratch dir should exist" || return 1
}
run_test "scratch creates and outputs directory path" test_scratch_changes_to_directory
