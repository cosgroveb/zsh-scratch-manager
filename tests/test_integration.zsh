#!/usr/bin/env zsh
# Integration test for scratch command

test_scratch_workflow() {
    # Create
    local scratch_dir
    scratch_dir=$(scratch "test" 2>&1 | grep "^${SCRATCH_DIR}")
    assert_directory_exists "$scratch_dir" || return 1

    # List shows it
    assert_output_contains "$(_scratch_list)" "test." || return 1

    # Cleanup preserves dir with file
    echo "x" > "${scratch_dir}/file.txt"
    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$scratch_dir"
    _scratch_cleanup
    assert_directory_exists "$scratch_dir" || return 1

    # Cleanup removes empty dir
    rm "${scratch_dir}/file.txt"
    _scratch_cleanup
    assert_directory_not_exists "$scratch_dir" || return 1
}
run_test "scratch workflow: create, list, cleanup" test_scratch_workflow
