#!/usr/bin/env zsh
# Tests for scratch directory cleanup

test_cleanup_removes_empty_directory() {
    # Create an empty scratch directory
    local dir
    dir=$(_scratch_create "empty" 2>&1)

    # Set age to 0 so it's eligible
    SCRATCH_CLEANUP_AGE=0

    # Make it look old by touching with past time
    touch -t 202001010000 "$dir"

    _scratch_cleanup

    assert_directory_not_exists "$dir" "Empty dir should be removed" || return 1
}
run_test "cleanup removes empty directories" test_cleanup_removes_empty_directory

test_cleanup_keeps_directory_with_files() {
    local dir
    dir=$(_scratch_create "hasfiles" 2>&1)

    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$dir"

    # Add a visible file
    touch "${dir}/important.txt"

    _scratch_cleanup

    assert_directory_exists "$dir" "Dir with files should be kept" || return 1
}
run_test "cleanup keeps directories with files" test_cleanup_keeps_directory_with_files

test_cleanup_keeps_git_directory() {
    local dir
    dir=$(_scratch_create "gitrepo" 2>&1)

    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$dir"

    # Make it a git repo
    mkdir "${dir}/.git"

    _scratch_cleanup

    assert_directory_exists "$dir" "Git repo should be kept" || return 1
}
run_test "cleanup keeps git directories" test_cleanup_keeps_git_directory

test_cleanup_keeps_young_directory() {
    local dir
    dir=$(_scratch_create "young" 2>&1)

    # Directory is brand new, should be kept
    SCRATCH_CLEANUP_AGE=3600

    _scratch_cleanup

    assert_directory_exists "$dir" "Young dir should be kept" || return 1
}
run_test "cleanup keeps directories younger than SCRATCH_CLEANUP_AGE" test_cleanup_keeps_young_directory

test_cleanup_removes_dir_with_only_hidden_tool_dirs() {
    local dir
    dir=$(_scratch_create "toolonly" 2>&1)

    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$dir"

    # Add hidden tool directories but no visible files
    mkdir -p "${dir}/.local/share"
    mkdir -p "${dir}/.config"
    mkdir -p "${dir}/.cache"

    _scratch_cleanup

    assert_directory_not_exists "$dir" "Dir with only hidden tool dirs should be removed" || return 1
}
run_test "cleanup removes directories with only hidden tool directories" test_cleanup_removes_dir_with_only_hidden_tool_dirs

test_cleanup_keeps_dir_with_hidden_dotfile() {
    local dir
    dir=$(_scratch_create "dotfile" 2>&1)

    SCRATCH_CLEANUP_AGE=0
    touch -t 202001010000 "$dir"

    # Add a user-created dotfile
    touch "${dir}/.env"

    _scratch_cleanup

    assert_directory_exists "$dir" "Dir with dotfile should be kept" || return 1
}
run_test "cleanup keeps directories with user dotfiles" test_cleanup_keeps_dir_with_hidden_dotfile
