# Scratch Picker Design

Date: 2026-03-29
Status: Approved for planning

## Summary

Add picker mode to `scratch` as `scratch --pick`. This mode selects an existing scratch directory under `$SCRATCH_DIR` and prints its absolute path. It does not create new directories.

Add two zsh wrappers:

- `sff() { scratch --pick "$@"; }`
- `sfp()`, which calls `scratch --pick`, then `pushd`s into the selected directory

This change covers non-volatile scratches only. `/tmp` scratches are out of scope.

## Command Surface

### `scratch --pick`

`scratch --pick` opens an interactive picker for directories under `$SCRATCH_DIR`.

Behavior:

- print the selected absolute path to stdout on success
- return non-zero on cancel, no candidates, or picker failure
- print no extra stdout output beyond the selected path
- use no short flag in this change

### `sff`

`sff` is a zsh function wrapper, not a standalone executable and not a shell alias.

```zsh
sff() { scratch --pick "$@"; }
```

Reason: this is already a zsh plugin. A function fits the current architecture and keeps the feature in the same loaded shell environment.

### `sfp`

`sfp` is a zsh function that navigates to the selected scratch directory.

Behavior:

- call `scratch --pick`
- if a path is selected, `pushd` into it
- print the selected path after successful navigation
- return non-zero if selection fails or `pushd` fails

## Internal Structure

Add a shared inventory helper for scratch directories under `$SCRATCH_DIR`. This helper is the source of truth for picker rows and list output.

The helper should produce machine-readable records with at least:

- absolute path
- display label

A tab-separated row is enough:

```text
/home/user/scratch/myproj.x2Lm<TAB>myproj.x2Lm  (2h) [in use] [git]
```

The display label should match the current list style:

```text
myproj.x2Lm  (2h) [in use] [git]
```

This helper replaces duplicated metadata work in the current list path. `scratch --list` should print the label field. `scratch --pick` should select from the same records and return the path field.

This is the key design choice in this change: human-readable list output is not an API. The picker should not parse `scratch --list`.

## Picker Behavior

### Candidate Scope

Only include directories directly under `$SCRATCH_DIR`.

Do not include `/tmp` or any volatile scratch location in this change.

### FZF Path

If `fzf` is available:

- feed picker rows from the shared inventory
- display the human label in the picker
- keep the absolute path available internally so selection does not depend on parsing label text
- print the selected absolute path to stdout

### Preview Pane

If `lsd` is available, use:

```sh
lsd --tree --color=always -- <selected-path>
```

If `lsd` is not available, preview by changing into the selected directory and running:

```sh
find . -print | sort | awk -F/ '{for(i=2;i<NF;i++)printf "│   ";if(NF>1)printf "├── ";print $NF}'
```

The fallback preview should run relative to the selected directory. That keeps the output short and keeps tree depth correct.

### `select` Fallback

If `fzf` is not available, fall back to `select`.

Use the same inventory data for this path. Do not use `select f in $(ls)`. Feed `select` from arrays so names with spaces stay intact.

The fallback still prints the selected absolute path on success and returns non-zero on cancel or no selection.

## Error Handling

Keep failure behavior tight:

- if there are no directories under `$SCRATCH_DIR`, print a concise stderr error and return non-zero
- if `fzf` exits without a selection, return non-zero and print nothing to stdout
- if `select` yields no valid selection, return non-zero and print nothing to stdout
- missing `lsd` is not an error, it only changes the preview command
- `sfp` should not print output that looks like a successful selection if `pushd` fails

The expected stderr style is short and concrete, for example:

```text
scratch: no scratch directories found
```

## Testing

Keep testing to one end-to-end update in `tests/run_tests.zsh`.

The new test should:

- create an isolated `$SCRATCH_DIR`
- create at least two scratch directories
- prepend a fake `fzf` to `PATH` so picker output is deterministic
- run `scratch --pick`
- assert that stdout is the selected absolute path
- run `sfp` and assert that the shell ends up in the selected directory

The test should not depend on a real interactive `fzf` session or a real `lsd` preview. It should stay end-to-end at the command level while controlling selection deterministically.

## Out of Scope

Do not bundle any broader CLI cleanup into this work.

Future cleanup idea:

- revisit `scratch` as subcommands such as `scratch create`, `scratch list`, `scratch cleanup`, and `scratch pick`

That idea belongs to a separate change.
