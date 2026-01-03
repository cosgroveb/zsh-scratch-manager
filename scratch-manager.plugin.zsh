#!/usr/bin/env zsh
# zsh-scratch-manager - Temporary scratch directory manager
# https://github.com/cosgroveb/zsh-scratch-manager

# Plugin directory
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
SCRATCH_MANAGER_DIR="${0:A:h}"

# Configuration defaults
: ${SCRATCH_DIR:="${HOME}/scratch"}
: ${SCRATCH_CLEANUP_PERIOD:=3600}
: ${SCRATCH_CLEANUP_AGE:=3600}
: ${SCRATCH_DEFAULT_PREFIX:=tmp}

# Add functions to fpath for autoloading
fpath=("${SCRATCH_MANAGER_DIR}/functions" $fpath)

# Source library files
for lib in "${SCRATCH_MANAGER_DIR}"/lib/*.zsh; do
    [[ -f "$lib" ]] && source "$lib"
done

# Autoload the main scratch function
autoload -Uz scratch

# Set up completion
autoload -Uz _scratch
compdef _scratch scratch
