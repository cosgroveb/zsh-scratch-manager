#!/usr/bin/env zsh
# Cleanup abandoned scratch directories

_scratch_cleanup() {
    local base_dir="${SCRATCH_DIR}"

    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    local now dir mtime age
    now=$(date +%s)
    zmodload -F zsh/stat b:zstat 2>/dev/null

    for dir in "${base_dir}"/*(/N); do
        [[ -d "$dir" ]] || continue

        # Skip if it's a git repo
        if [[ -d "${dir}/.git" ]]; then
            continue
        fi

        # Skip if in use
        if _scratch_dir_in_use "$dir"; then
            continue
        fi

        # Skip if too young
        if zstat -A mtime +mtime "$dir" &>/dev/null; then
            age=$((now - mtime[1]))
            if (( age < SCRATCH_CLEANUP_AGE )); then
                continue
            fi
        fi

        # Check if effectively empty (no user content)
        if _scratch_dir_is_empty "$dir"; then
            rm -rf "$dir"
        fi
    done
}

_scratch_dir_is_empty() {
    local dir="$1"
    local item item_name is_ignored ignored

    # Check for any visible files (not starting with .)
    local visible_files
    visible_files=("${dir}"/*(N))
    if (( ${#visible_files} > 0 )); then
        return 1  # Has visible files, not empty
    fi

    # Check hidden items
    for item in "${dir}"/.[^.]*(N); do
        item_name="${item:t}"

        # If it's in the ignore list, skip it (doesn't count as user content)
        is_ignored=0
        for ignored in "${SCRATCH_IGNORE_HIDDEN[@]}"; do
            if [[ "$item_name" == "$ignored" ]]; then
                is_ignored=1
                break
            fi
        done

        if (( is_ignored )); then
            continue
        fi

        # Found a hidden file/dir not in ignore list - user content exists
        return 1
    done

    # No user content found
    return 0
}
