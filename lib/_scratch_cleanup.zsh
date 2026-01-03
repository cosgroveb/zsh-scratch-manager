#!/usr/bin/env zsh
# Cleanup abandoned scratch directories

# Hidden directories created by tools that don't indicate user work
typeset -ga _SCRATCH_TOOL_DIRS=(.local .config .cache .npm .yarn .pnpm)

_scratch_cleanup() {
    local base_dir="${SCRATCH_DIR}"

    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    local now
    now=$(date +%s)

    local dir
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
        local mtime age
        zmodload -F zsh/stat b:zstat 2>/dev/null
        if zstat -A mtime +mtime "$dir" 2>/dev/null; then
            age=$((now - mtime))
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
    local item item_name is_tool_dir tool_dir_name

    # Check for any visible files (not starting with .)
    local visible_files
    visible_files=("${dir}"/*(N))
    if (( ${#visible_files} > 0 )); then
        return 1  # Has visible files, not empty
    fi

    # Check hidden items
    for item in "${dir}"/.[^.]*(N); do
        item_name="${item:t}"

        # If it's a known tool directory, skip it (doesn't count as user content)
        is_tool_dir=0
        for tool_dir_name in "${_SCRATCH_TOOL_DIRS[@]}"; do
            if [[ "$item_name" == "$tool_dir_name" ]]; then
                is_tool_dir=1
                break
            fi
        done

        if (( is_tool_dir )); then
            continue
        fi

        # Found a hidden file/dir that's not a tool dir - user content exists
        return 1
    done

    # No user content found
    return 0
}
