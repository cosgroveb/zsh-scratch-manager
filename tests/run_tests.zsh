#!/usr/bin/env zsh
# Test for zsh-scratch-manager

source "${0:A:h:h}/scratch-manager.plugin.zsh"

# Setup isolated environment
TEST_TMP="$(mktemp -d)"
export SCRATCH_DIR="${TEST_TMP}/scratch"
export SCRATCH_CLEANUP_AGE=3600
mkdir -p "$SCRATCH_DIR"
mkdir -p "${TEST_TMP}/bin"
START_DIR="$PWD"

cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

scratch_dir=$(scratch "test" 2>&1 | grep "^${SCRATCH_DIR}")
[[ -d "$scratch_dir" ]] || { echo "FAIL: create"; exit 1; }
[[ "$(_scratch_list)" == *"test."* ]] || { echo "FAIL: list"; exit 1; }

tab_dir=$(scratch $'tab\tname' 2>&1 | grep "^${SCRATCH_DIR}")
[[ -d "$tab_dir" ]] || { echo "FAIL: tabbed create"; exit 1; }
[[ "$(_scratch_list)" == *$'tab\tname.'* ]] || { echo "FAIL: list lost tabbed name"; exit 1; }

echo "x" > "${scratch_dir}/file.txt"
SCRATCH_CLEANUP_AGE=0; touch -t 202001010000 "$scratch_dir"
_scratch_cleanup
[[ -d "$scratch_dir" ]] || { echo "FAIL: cleanup preserved"; exit 1; }

rm "${scratch_dir}/file.txt"
_scratch_cleanup
[[ ! -d "$scratch_dir" ]] || { echo "FAIL: cleanup removed"; exit 1; }

cat > "${TEST_TMP}/bin/fzf" <<'EOF'
#!/usr/bin/env zsh

while [[ $# -gt 0 ]]; do
    shift
done

while IFS= read -r line; do
    [[ "$line" == *"${SCRATCH_TEST_PICK_MATCH}"* ]] || continue
    print -r -- "$line"
    exit 0
done

exit 1
EOF
chmod +x "${TEST_TMP}/bin/fzf"

scratch "pick-one" > /dev/null 2>&1
second_pick=$(scratch "pick-two" 2>&1 | grep "^${SCRATCH_DIR}")
cd "$START_DIR" || exit 1

export PATH="${TEST_TMP}/bin:${PATH}"
export SCRATCH_TEST_PICK_MATCH="pick-two."

picked_dir=$(scratch --pick)
[[ "${picked_dir}" == "${second_pick}" ]] || { echo "FAIL: pick returned wrong path"; exit 1; }

sfp > "${TEST_TMP}/sfp.out" || { echo "FAIL: sfp exited non-zero"; exit 1; }
sfp_output=$(<"${TEST_TMP}/sfp.out")
[[ "${sfp_output}" == "${second_pick}" ]] || { echo "FAIL: sfp returned wrong path"; exit 1; }
[[ "${PWD}" == "${second_pick}" ]] || { echo "FAIL: sfp did not change directory"; exit 1; }

echo "PASS"
