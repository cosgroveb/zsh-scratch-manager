#!/usr/bin/env zsh
# Pick existing scratch directories

_scratch_pick() {
    local selected_path

    selected_path=$(_scratch_pick_path) || return 1
    print -r -- "$selected_path"
}

_scratch_pick_path() {
    local include_create=0
    local -a rows labels path_map
    local selected choice paths_file selection_index selection_path
    local i

    if [[ "$1" == "--include-create" ]]; then
        include_create=1
    fi

    _scratch_inventory_load

    if (( ${#_scratch_inventory_paths[@]} == 0 && ! include_create )); then
        echo "scratch: no scratch directories found" >&2
        return 1
    fi

    if (( include_create )); then
        rows+=("1"$'\t'"+ new scratch"$'\t'"$(_scratch_pick_hidden_tokens 'new scratch create')")
        labels+=("+ new scratch")
        path_map+=("__SCRATCH_CREATE__")
    fi

    for (( i = 1; i <= ${#_scratch_inventory_paths[@]}; i++ )); do
        rows+=("$(( ${#path_map[@]} + 1 ))"$'\t'"${_scratch_inventory_picker_rows[$i]}"$'\t'"$(_scratch_pick_hidden_tokens "${_scratch_inventory_tokens[$i]}")")
        labels+=("${_scratch_inventory_labels[$i]}")
        path_map+=("${_scratch_inventory_paths[$i]}")
    done

    if command -v fzf >/dev/null 2>&1; then
        paths_file=$(mktemp) || {
            echo "scratch: failed to prepare picker state" >&2
            return 1
        }
        printf '%s\n' "${path_map[@]}" > "$paths_file"

        selected=$(
            printf '%s\n' "${rows[@]}" |
                SCRATCH_PICK_PATHS_FILE="$paths_file" fzf \
                    --ansi \
                    --delimiter=$'\t' \
                    --with-nth=2,3 \
                    --preview "$(_scratch_pick_preview_command)" \
                    --preview-window=right:60%
        )

        if [[ -n "$selected" ]]; then
            selection_index="${selected%%$'\t'*}"
            [[ "$selection_index" == <-> ]] || {
                rm -f "$paths_file"
                return 1
            }

            selection_path=$(sed -n "${selection_index}p" "$paths_file")
        fi

        rm -f "$paths_file"
        [[ -n "$selected" ]] || return 1
        [[ -n "$selection_path" ]] || return 1
        print -r -- "$selection_path"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "scratch: cannot use select without a terminal" >&2
        return 1
    fi

    PS3="Select a scratch directory: "
    select choice in "${labels[@]}"; do
        [[ -n "$choice" ]] || continue
        print -r -- "${path_map[$REPLY]}"
        return 0
    done

    return 1
}

_scratch_pick_hidden_tokens() {
    local tokens="$1"
    printf '\033[8m%s\033[0m' "$tokens"
}

_scratch_pick_preview_command() {
    cat <<'EOF'
line={}
selection_index=$(printf '%s\n' "$line" | cut -f1)
scratch_path=$(sed -n "${selection_index}p" "$SCRATCH_PICK_PATHS_FILE")
if [[ -z "$scratch_path" || "$scratch_path" == "__SCRATCH_CREATE__" ]]; then
    exit 0
fi
if command -v lsd >/dev/null 2>&1; then
    lsd --tree --color=always -- "$scratch_path"
else
    cd -- "$scratch_path" 2>/dev/null || exit 0
    find . -print | sort | awk -F/ '{for(i=2;i<NF;i++)printf "│   ";if(NF>1)printf "├── ";print $NF}'
fi
EOF
}
