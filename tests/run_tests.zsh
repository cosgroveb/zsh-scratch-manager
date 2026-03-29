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
REAL_FZF_BIN="$(command -v fzf)"

cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

scratch_dir=$(scratch "test" 2>&1 | grep "^${SCRATCH_DIR}")
[[ -d "$scratch_dir" ]] || { echo "FAIL: create"; exit 1; }
[[ "$(_scratch_list)" == *"test."* ]] || { echo "FAIL: list"; exit 1; }
touch -t 202001010000 "$scratch_dir"

tab_dir=$(scratch $'tab\tname' 2>&1 | grep "^${SCRATCH_DIR}")
[[ -d "$tab_dir" ]] || { echo "FAIL: tabbed create"; exit 1; }
[[ "$(_scratch_list)" == *$'tab\tname.'* ]] || { echo "FAIL: list lost tabbed name"; exit 1; }
touch -t 202001010000 "$tab_dir"

scratch "old-order" > /dev/null 2>&1
newest_dir=$(scratch "new-order" 2>&1 | grep "^${SCRATCH_DIR}")
touch -t 202001010000 "${SCRATCH_DIR}"/old-order.*
list_output=$(_scratch_list)
[[ "${list_output%%$'\n'*}" == new-order.* ]] || { echo "FAIL: list did not sort newest first"; exit 1; }

echo "x" > "${scratch_dir}/file.txt"
SCRATCH_CLEANUP_AGE=0; touch -t 202001010000 "$scratch_dir"
_scratch_cleanup
[[ -d "$scratch_dir" ]] || { echo "FAIL: cleanup preserved"; exit 1; }

rm "${scratch_dir}/file.txt"
_scratch_cleanup
[[ ! -d "$scratch_dir" ]] || { echo "FAIL: cleanup removed"; exit 1; }

cat > "${TEST_TMP}/bin/fzf" <<'EOF'
#!/usr/bin/env zsh

exec "${SCRATCH_REAL_FZF}" --filter "${SCRATCH_TEST_PICK_MATCH}" "$@"
EOF
chmod +x "${TEST_TMP}/bin/fzf"

scratch "pick-one" > /dev/null 2>&1
second_pick=$(scratch "pick-two" 2>&1 | grep "^${SCRATCH_DIR}")
mkdir -p "${second_pick}/notes"
echo "hello" > "${second_pick}/notes/needle.txt"
cd "$START_DIR" || exit 1

_scratch_inventory_load
picker_row=""
for picker_row in "${_scratch_inventory_picker_rows[@]}"; do
    [[ "$picker_row" == *needle.txt* ]] || continue
    break
done
[[ "$picker_row" == *$'|'* ]] || { echo "FAIL: picker row missing separator"; exit 1; }
[[ "$picker_row" == *$'\033[36m'* ]] || { echo "FAIL: picker row missing hint color"; exit 1; }

export PATH="${TEST_TMP}/bin:${PATH}"
export SCRATCH_REAL_FZF="${REAL_FZF_BIN}"
export SCRATCH_TEST_PICK_MATCH="needle.txt"

picked_dir=$(scratch --pick)
[[ "${picked_dir}" == "${second_pick}" ]] || { echo "FAIL: pick returned wrong path"; exit 1; }

sfp > "${TEST_TMP}/sfp.out" || { echo "FAIL: sfp exited non-zero"; exit 1; }
sfp_output=$(<"${TEST_TMP}/sfp.out")
[[ "${sfp_output}" == "${second_pick}" ]] || { echo "FAIL: sfp returned wrong path"; exit 1; }
[[ "${PWD}" == "${second_pick}" ]] || { echo "FAIL: sfp did not change directory"; exit 1; }

cd "$START_DIR" || exit 1
export SCRATCH_TEST_PICK_MATCH="+ new scratch"

scratch-find-or-create > "${TEST_TMP}/find_or_create_create.out" || { echo "FAIL: find-or-create create exited non-zero"; exit 1; }
created_from_picker=$(<"${TEST_TMP}/find_or_create_create.out")
[[ "${created_from_picker}" == "${SCRATCH_DIR}"/tmp.* ]] || { echo "FAIL: find-or-create did not create"; exit 1; }
[[ -d "${created_from_picker}" ]] || { echo "FAIL: created scratch missing"; exit 1; }
[[ "${PWD}" == "${created_from_picker}" ]] || { echo "FAIL: find-or-create did not cd after create"; exit 1; }

cd "$START_DIR" || exit 1
export SCRATCH_TEST_PICK_MATCH="needle.txt"

scratch-find-or-create > "${TEST_TMP}/find_or_create_open.out" || { echo "FAIL: find-or-create open exited non-zero"; exit 1; }
opened_from_picker=$(<"${TEST_TMP}/find_or_create_open.out")
[[ "${opened_from_picker}" == "${second_pick}" ]] || { echo "FAIL: find-or-create selected wrong existing scratch"; exit 1; }
[[ "${PWD}" == "${second_pick}" ]] || { echo "FAIL: find-or-create did not cd to existing scratch"; exit 1; }

echo "PASS"
