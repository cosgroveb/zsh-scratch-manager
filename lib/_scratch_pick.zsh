#!/usr/bin/env zsh
# Pick existing scratch directories

_scratch_pick() {
    local -a rows
    local selected choice paths_file selection_index
    local i

    _scratch_inventory_load

    if (( ${#_scratch_inventory_paths[@]} == 0 )); then
        echo "scratch: no scratch directories found" >&2
        return 1
    fi

    for (( i = 1; i <= ${#_scratch_inventory_paths[@]}; i++ )); do
        rows+=("${i}"$'\t'"${_scratch_inventory_labels[$i]}")
    done

    if command -v fzf >/dev/null 2>&1; then
        paths_file=$(mktemp) || {
            echo "scratch: failed to prepare picker state" >&2
            return 1
        }
        printf '%s\n' "${_scratch_inventory_paths[@]}" > "$paths_file"

        selected=$(
            printf '%s\n' "${rows[@]}" |
                SCRATCH_PICK_PATHS_FILE="$paths_file" fzf \
                    --delimiter=$'\t' \
                    --with-nth=2.. \
                    --preview "$(_scratch_pick_preview_command)" \
                    --preview-window=right:60%
        )
        rm -f "$paths_file"

        [[ -n "$selected" ]] || return 1
        selection_index="${selected%%$'\t'*}"
        [[ "$selection_index" == <-> ]] || return 1

        print -r -- "${_scratch_inventory_paths[$selection_index]}"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "scratch: cannot use select without a terminal" >&2
        return 1
    fi

    PS3="Select a scratch directory: "
    select choice in "${_scratch_inventory_labels[@]}"; do
        [[ -n "$choice" ]] || continue
        print -r -- "${_scratch_inventory_paths[$REPLY]}"
        return 0
    done

    return 1
}

_scratch_pick_preview_command() {
    cat <<'EOF'
line={}
selection_index=$(printf '%s\n' "$line" | cut -f1)
scratch_path=$(sed -n "${selection_index}p" "$SCRATCH_PICK_PATHS_FILE")
if command -v lsd >/dev/null 2>&1; then
    lsd --tree --color=always -- "$scratch_path"
else
    cd -- "$scratch_path" 2>/dev/null || exit 0
    find . -print | sort | awk -F/ '{for(i=2;i<NF;i++)printf "│   ";if(NF>1)printf "├── ";print $NF}'
fi
EOF
}
