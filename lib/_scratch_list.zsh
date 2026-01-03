#!/usr/bin/env zsh
# List scratch directories

_scratch_list() {
    local base_dir="${SCRATCH_DIR}"

    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    local now
    now=$(date +%s)

    local dir
    for dir in "${base_dir}"/*(/N); do
        [[ -d "$dir" ]] || continue

        local dir_name="${dir:t}"
        local mtime age age_str

        # Get modification time using zsh stat
        zmodload -F zsh/stat b:zstat 2>/dev/null
        if zstat -A mtime +mtime "$dir" &>/dev/null; then
            age=$((now - mtime[1]))
            age_str=$(_format_age $age)
        else
            age_str="?"
        fi

        # Check if in use (any shell has CWD in this dir)
        local in_use=""
        if _scratch_dir_in_use "$dir"; then
            in_use=" [in use]"
        fi

        # Check if it's a git repo
        local is_git=""
        if [[ -d "${dir}/.git" ]]; then
            is_git=" [git]"
        fi

        echo "${dir_name}  (${age_str})${in_use}${is_git}"
    done
}

_format_age() {
    local seconds=$1

    if (( seconds < 60 )); then
        echo "${seconds}s"
    elif (( seconds < 3600 )); then
        echo "$((seconds / 60))m"
    elif (( seconds < 86400 )); then
        echo "$((seconds / 3600))h"
    else
        echo "$((seconds / 86400))d"
    fi
}

_scratch_dir_in_use() {
    local dir="$1"

    # Platform-specific CWD detection
    if [[ -d /proc ]]; then
        # Linux: check /proc/*/cwd symlinks
        local proc_dir
        for proc_dir in /proc/[0-9]*/cwd(N); do
            local cwd
            cwd=$(readlink "$proc_dir" 2>/dev/null) || continue
            if [[ "$cwd" == "$dir" || "$cwd" == "$dir"/* ]]; then
                return 0
            fi
        done
    else
        # macOS: use lsof
        if command -v lsof >/dev/null 2>&1; then
            if lsof +d "$dir" >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi

    return 1
}
