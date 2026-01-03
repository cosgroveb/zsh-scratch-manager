#!/usr/bin/env zsh
# Test for zsh-scratch-manager

source "${0:A:h:h}/scratch-manager.plugin.zsh"

# Setup isolated environment
TEST_TMP="$(mktemp -d)"
export SCRATCH_DIR="${TEST_TMP}/scratch"
export SCRATCH_CLEANUP_AGE=3600
mkdir -p "$SCRATCH_DIR"

cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

# Test
scratch_dir=$(scratch "test" 2>&1 | grep "^${SCRATCH_DIR}")
[[ -d "$scratch_dir" ]] || { echo "FAIL: create"; exit 1; }
[[ "$(_scratch_list)" == *"test."* ]] || { echo "FAIL: list"; exit 1; }

echo "x" > "${scratch_dir}/file.txt"
SCRATCH_CLEANUP_AGE=0; touch -t 202001010000 "$scratch_dir"
_scratch_cleanup
[[ -d "$scratch_dir" ]] || { echo "FAIL: cleanup preserved"; exit 1; }

rm "${scratch_dir}/file.txt"
_scratch_cleanup
[[ ! -d "$scratch_dir" ]] || { echo "FAIL: cleanup removed"; exit 1; }

echo "PASS"
