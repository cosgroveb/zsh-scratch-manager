#!/usr/bin/env zsh
# Shared inventory for scratch directories

typeset -ga _scratch_inventory_paths
typeset -ga _scratch_inventory_labels
typeset -ga _scratch_inventory_tokens
typeset -ga _scratch_inventory_picker_rows

_scratch_inventory_load() {
    local base_dir="${SCRATCH_DIR}"
    local insert_at

    _scratch_inventory_paths=()
    _scratch_inventory_labels=()
    _scratch_inventory_tokens=()
    _scratch_inventory_picker_rows=()

    if [[ ! -d "$base_dir" ]]; then
        return 0
    fi

    local now dir dir_name mtime age age_str label tokens picker_row
    local in_use=0
    local has_git=0
    now=$(date +%s)
    zmodload -F zsh/stat b:zstat 2>/dev/null

    for dir in "${base_dir}"/*(/N); do
        [[ -d "$dir" ]] || continue
        in_use=0
        has_git=0

        dir_name="${dir:t}"

        if zstat -A mtime +mtime "$dir" &>/dev/null; then
            age=$((now - mtime[1]))
            age_str=$(_scratch_format_age "$age")
        else
            age_str="?"
        fi

        label="${dir_name}  (${age_str})"

        if _scratch_dir_in_use "$dir"; then
            in_use=1
            label="${label} [in use]"
        fi

        if [[ -d "${dir}/.git" ]]; then
            has_git=1
            label="${label} [git]"
        fi

        tokens=$(_scratch_search_tokens "$dir")
        picker_row=$(_scratch_picker_row "$dir_name" "$age_str" "$tokens" "$in_use" "$has_git")
        insert_at=$(_scratch_inventory_insert_index "$mtime")

        _scratch_inventory_paths=(
            "${_scratch_inventory_paths[@]:0:$((insert_at - 1))}"
            "$dir"
            "${_scratch_inventory_paths[@]:$((insert_at - 1))}"
        )
        _scratch_inventory_labels=(
            "${_scratch_inventory_labels[@]:0:$((insert_at - 1))}"
            "$label"
            "${_scratch_inventory_labels[@]:$((insert_at - 1))}"
        )
        _scratch_inventory_tokens=(
            "${_scratch_inventory_tokens[@]:0:$((insert_at - 1))}"
            "$tokens"
            "${_scratch_inventory_tokens[@]:$((insert_at - 1))}"
        )
        _scratch_inventory_picker_rows=(
            "${_scratch_inventory_picker_rows[@]:0:$((insert_at - 1))}"
            "$picker_row"
            "${_scratch_inventory_picker_rows[@]:$((insert_at - 1))}"
        )
    done
}

_scratch_inventory_insert_index() {
    local candidate_mtime="$1"
    local i existing_mtime

    for (( i = 1; i <= ${#_scratch_inventory_paths[@]}; i++ )); do
        if zstat -A existing_mtime +mtime "${_scratch_inventory_paths[$i]}" &>/dev/null; then
            (( candidate_mtime >= existing_mtime[1] )) && {
                echo "$i"
                return 0
            }
        fi
    done

    echo "$(( ${#_scratch_inventory_paths[@]} + 1 ))"
}

_scratch_search_tokens() {
    local dir="$1"

    (
        cd -- "$dir" 2>/dev/null || exit 0
        find . -mindepth 1 -maxdepth 2 -print 2>/dev/null |
            LC_ALL=C sort |
            awk '{
                gsub(/^[.]\//, "", $0)
                gsub(/\t/, " ", $0)
                gsub(/\r/, " ", $0)
                printf "%s ", $0
            }'
    )
}

_scratch_visible_hints() {
    local tokens="$1"
    local limit=56
    local entry output=""
    local used=0
    local remaining
    local -a entries

    entries=(${=tokens})

    for entry in "${entries[@]}"; do
        [[ -n "$entry" ]] || continue

        remaining=$((limit - used))
        (( remaining <= 0 )) && break

        if (( used == 0 )); then
            if (( ${#entry} > remaining )); then
                output="${entry[1,$((remaining - 2))]}.."
                break
            fi
            output="$entry"
            used=${#entry}
            continue
        fi

        if (( ${#entry} + 1 > remaining )); then
            output="${output} .."
            break
        fi

        output="${output} ${entry}"
        used=$((used + ${#entry} + 1))
    done

    print -r -- "$output"
}

_scratch_picker_row() {
    local dir_name="$1"
    local age_str="$2"
    local tokens="$3"
    local in_use="$4"
    local has_git="$5"
    local hints label
    local reset=$'\033[0m'
    local dim=$'\033[90m'
    local yellow=$'\033[33m'
    local green=$'\033[32m'
    local cyan=$'\033[36m'

    label="${dir_name}  (${age_str})"
    (( in_use )) && label="${label} ${yellow}[in use]${reset}"
    (( has_git )) && label="${label} ${green}[git]${reset}"

    hints=$(_scratch_visible_hints "$tokens")
    [[ -n "$hints" ]] || {
        print -r -- "$label"
        return 0
    }

    print -r -- "${label} ${dim}|${reset} ${cyan}${hints}${reset}"
}

_scratch_format_age() {
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
        local proc_dir cwd
        for proc_dir in /proc/[0-9]*/cwd(N); do
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
