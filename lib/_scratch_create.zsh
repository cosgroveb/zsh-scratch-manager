#!/usr/bin/env zsh
# Scratch directory creation

_scratch_create() {
    local prefix="${1:-${SCRATCH_DEFAULT_PREFIX}}"
    local base_dir="${SCRATCH_DIR}"

    # Ensure base directory exists
    if [[ ! -d "$base_dir" ]]; then
        if ! mkdir -p "$base_dir" 2>/dev/null; then
            echo "error: failed to create base directory: $base_dir" >&2
            return 1
        fi
    fi

    # Create scratch directory with random suffix
    # Use explicit template for macOS compatibility
    local scratch_dir
    scratch_dir=$(mktemp -d "${base_dir}/${prefix}.XXXX" 2>/dev/null)

    if [[ -z "$scratch_dir" || ! -d "$scratch_dir" ]]; then
        echo "error: failed to create scratch directory" >&2
        return 1
    fi

    echo "$scratch_dir"
    return 0
}
