#!/usr/bin/env zsh
# Test runner for zsh-scratch-manager

set -e

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"

# Source the plugin (sets up fpath, sources libs)
source "${PROJECT_DIR}/scratch-manager.plugin.zsh"

# Source test helper
source "${SCRIPT_DIR}/test_helper.zsh"

# Find and run all test files
for test_file in "${SCRIPT_DIR}"/test_*.zsh; do
    [[ "$test_file" == "${SCRIPT_DIR}/test_helper.zsh" ]] && continue
    [[ -f "$test_file" ]] || continue

    echo ""
    echo "Running: ${test_file:t}"
    echo "--------------------------------"
    source "$test_file"
done

# Print summary and exit with appropriate code
test_summary
exit $?
