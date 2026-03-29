# Scratch Find-Or-Create Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable plugin helper and widget for interactive scratch find-or-create, then bind it in personal dotfiles as `Alt-o`.

**Architecture:** Keep the existing CLI commands unchanged and add a new helper path for the interactive combined flow. Reuse the existing scratch inventory and picker internals, add one synthetic `+ new scratch` row, and keep the personal keybinding in the chezmoi-managed zsh config.

**Tech Stack:** zsh, ZLE widgets, existing `fzf` picker support, chezmoi-managed dotfiles, single end-to-end zsh test script

---

### Task 1: Add the failing end-to-end test

**Files:**
- Modify: `tests/run_tests.zsh`

- [ ] **Step 1: Write the failing test**

Add a new section near the picker assertions that exercises both the synthetic `+ new scratch` row and an existing scratch selection. The test should stub `fzf` to return either the synthetic row or an existing match, invoke the new helper, and assert the resulting path plus `PWD`.

```zsh
export SCRATCH_TEST_PICK_MATCH="+ new scratch"
created_from_picker=$(scratch-find-or-create)
[[ "${created_from_picker}" == "${SCRATCH_DIR}"/tmp.* ]] || { echo "FAIL: find-or-create did not create"; exit 1; }
[[ "${PWD}" == "${created_from_picker}" ]] || { echo "FAIL: find-or-create did not cd after create"; exit 1; }

cd "$START_DIR" || exit 1
export SCRATCH_TEST_PICK_MATCH="needle.txt"
opened_from_picker=$(scratch-find-or-create)
[[ "${opened_from_picker}" == "${second_pick}" ]] || { echo "FAIL: find-or-create selected wrong existing scratch"; exit 1; }
[[ "${PWD}" == "${second_pick}" ]] || { echo "FAIL: find-or-create did not cd to existing scratch"; exit 1; }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `zsh tests/run_tests.zsh`
Expected: FAIL with `scratch-find-or-create: command not found` or equivalent missing-helper failure.

### Task 2: Implement the helper and widget

**Files:**
- Create: `lib/_scratch_find_or_create.zsh`
- Modify: `scratch-manager.plugin.zsh`

- [ ] **Step 1: Write minimal helper implementation**

Add a new library helper that:
- loads scratch inventory
- prepends a synthetic `+ new scratch` row in `fzf`
- creates a new scratch when that synthetic row is selected
- otherwise `pushd`s to the selected existing scratch
- prints the resulting absolute path
- returns non-zero on cancel

```zsh
_scratch_find_or_create() {
    local selected scratch_dir

    selected=$(_scratch_pick_or_create_path) || return 1

    if [[ "$selected" == "__SCRATCH_CREATE__" ]]; then
        scratch_dir=$(_scratch_create "${SCRATCH_DEFAULT_PREFIX}") || return 1
    else
        scratch_dir="$selected"
    fi

    pushd "$scratch_dir" > /dev/null 2>&1 || {
        echo "scratch: failed to change to directory: $scratch_dir" >&2
        return 1
    }

    echo "$scratch_dir"
}
```

- [ ] **Step 2: Add widget and function export**

Expose a shell function and widget from the plugin file so user dotfiles can bind them without reimplementing behavior.

```zsh
scratch-find-or-create() { _scratch_find_or_create "$@"; }

scratch-find-or-create-widget() {
    scratch-find-or-create && zle reset-prompt
}
zle -N scratch-find-or-create-widget
```

- [ ] **Step 3: Run test to verify it passes**

Run: `zsh tests/run_tests.zsh`
Expected: PASS

### Task 3: Add optional docs and personal keybinding

**Files:**
- Modify: `README.md`
- Modify: `/home/bcosgrove/.local/share/chezmoi/home/dot_zshrc_personal.tmpl`

- [ ] **Step 1: Add short README example**

Document the optional `Alt-o` widget as a compact usage example rather than a core feature section.

```zsh
bindkey '^[o' scratch-find-or-create-widget
```

- [ ] **Step 2: Add the personal bind in chezmoi source**

Replace the old `^G` scratch binding with the new `Alt-o` binding in the chezmoi-managed zsh config.

```zsh
bindkey '^[o' scratch-find-or-create-widget
```

- [ ] **Step 3: Preview and apply with chezmoi**

Run: `chezmoi diff`
Expected: shows the `Alt-o` binding change

Run: `chezmoi cat ~/.zshrc_personal | sed -n '25,45p'`
Expected: rendered config contains `bindkey '^[o' scratch-find-or-create-widget`

Run: `chezmoi apply --refresh-externals --force`
Expected: no errors

### Task 4: Verify, review, and publish

**Files:**
- Verify: `tests/run_tests.zsh`

- [ ] **Step 1: Run verification**

Run: `zsh tests/run_tests.zsh`
Expected: PASS

Run: `zsh -ic 'source ~/.zshrc_personal >/dev/null 2>&1; bindkey | grep "\\^\\[o"'`
Expected: shows `scratch-find-or-create-widget`

- [ ] **Step 2: Request code review**

Use the review subagent against the implementation diff from the current branch tip before the feature commit to `HEAD`.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-03-29-scratch-find-or-create.md \
  lib/_scratch_find_or_create.zsh \
  scratch-manager.plugin.zsh \
  tests/run_tests.zsh \
  README.md
git commit -m "Add scratch find-or-create helper"
```

- [ ] **Step 4: Push**

```bash
git push git@github.com:cosgroveb/zsh-scratch-manager.git main
```
