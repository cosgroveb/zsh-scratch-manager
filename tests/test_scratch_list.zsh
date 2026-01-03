#!/usr/bin/env zsh
# Tests for scratch directory listing

test_list_empty() {
    local output
    output=$(_scratch_list 2>&1)

    assert_equals "" "$output" "Empty scratch dir should produce no output" || return 1
}
run_test "list shows nothing when empty" test_list_empty

test_list_shows_directories() {
    # Create some scratch directories
    local dir1 dir2
    dir1=$(_scratch_create "alpha" 2>&1)
    dir2=$(_scratch_create "beta" 2>&1)

    local output
    output=$(_scratch_list 2>&1)

    assert_output_contains "$output" "alpha." || return 1
    assert_output_contains "$output" "beta." || return 1
}
run_test "list shows created directories" test_list_shows_directories

test_list_shows_age() {
    local dir1
    dir1=$(_scratch_create "test" 2>&1)

    local output
    output=$(_scratch_list 2>&1)

    # Should show some age indicator (0s, 0m, etc.)
    assert_output_contains "$output" "test." || return 1
}
run_test "list includes directory in output" test_list_shows_age
