#!/usr/bin/env zsh
# List scratch directories

_scratch_list() {
    local i

    _scratch_inventory_load

    for (( i = 1; i <= ${#_scratch_inventory_labels[@]}; i++ )); do
        print -r -- "${_scratch_inventory_labels[$i]}"
    done
}
