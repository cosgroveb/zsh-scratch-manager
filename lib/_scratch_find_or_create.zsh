#!/usr/bin/env zsh
# Find or create a scratch directory, then enter it

scratch-find-or-create() {
    _scratch_find_or_create "$@"
}

_scratch_find_or_create() {
    local scratch_dir

    scratch_dir=$(_scratch_pick_path --include-create) || return 1

    if [[ "$scratch_dir" == "__SCRATCH_CREATE__" ]]; then
        scratch_dir=$(_scratch_create "${SCRATCH_DEFAULT_PREFIX}") || return 1
    fi

    if ! pushd "$scratch_dir" > /dev/null 2>&1; then
        echo "scratch: failed to change to directory: $scratch_dir" >&2
        return 1
    fi

    print -r -- "$scratch_dir"
}
