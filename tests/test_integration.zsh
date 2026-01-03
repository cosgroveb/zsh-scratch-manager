#!/usr/bin/env zsh
# Integration tests for scratch command

test_full_workflow() {
    # Create a scratch directory
    local output
    output=$(scratch "integration" 2>&1)
    local scratch_dir
    scratch_dir=$(echo "$output" | grep "^${SCRATCH_DIR}")

    assert_directory_exists "$scratch_dir" "Scratch dir should be created" || return 1

    # List should show it
    local list_output
    list_output=$(_scratch_list 2>&1)
    assert_output_contains "$list_output" "integration." || return 1

    # Add a file so it won't be cleaned
    echo "test" > "${scratch_dir}/test.txt"

    # Cleanup should keep it (has file)
    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$scratch_dir"
    _scratch_cleanup
    assert_directory_exists "$scratch_dir" "Dir with file should survive cleanup" || return 1

    # Remove file, cleanup should remove it
    rm "${scratch_dir}/test.txt"
    _scratch_cleanup
    assert_directory_not_exists "$scratch_dir" "Empty dir should be cleaned" || return 1
}
run_test "full create-list-cleanup workflow" test_full_workflow

test_tmp_flag() {
    SCRATCH_DIR="${TEST_TMP_DIR}/scratch"

    # Run in subshell to avoid polluting test environment
    local output
    output=$(
        cd "$TEST_TMP_DIR"
        scratch -t "tmptest" 2>&1
        pwd
    )

    # Should have created in /tmp
    assert_output_contains "$output" "/tmp/tmptest." || return 1
}
run_test "-t flag creates in /tmp" test_tmp_flag

test_help_output() {
    local output
    output=$(scratch --help 2>&1)

    assert_output_contains "$output" "scratch - Create and manage" || return 1
    assert_output_contains "$output" "Usage:" || return 1
    assert_output_contains "$output" "SCRATCH_DIR" || return 1
}
run_test "--help shows usage information" test_help_output
