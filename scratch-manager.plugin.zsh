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

# Hidden files/dirs ignored during cleanup (don't count as user content)
if [[ -z "${SCRATCH_IGNORE_HIDDEN+x}" ]]; then
    SCRATCH_IGNORE_HIDDEN=(.local .config .cache .npm .yarn .pnpm .claude)
fi

# Add functions to fpath for autoloading
fpath=("${SCRATCH_MANAGER_DIR}/functions" $fpath)

# Source library files
for lib in "${SCRATCH_MANAGER_DIR}"/lib/*.zsh; do
    [[ -f "$lib" ]] && source "$lib"
done

# Autoload the main scratch function (if it exists)
if [[ -f "${SCRATCH_MANAGER_DIR}/functions/scratch" ]]; then
    autoload -Uz scratch
fi

# Set up completion (if completion system is available)
if [[ -f "${SCRATCH_MANAGER_DIR}/functions/_scratch" ]] && (( $+functions[compdef] )); then
    autoload -Uz _scratch
    compdef _scratch scratch
fi

# Widget for key binding (bind with: bindkey '^S' scratch-widget)
scratch-widget() { scratch && zle reset-prompt }
zle -N scratch-widget

# Auto-cleanup setup
# Run cleanup periodically (uses zsh periodic hook)
PERIOD="${SCRATCH_CLEANUP_PERIOD}"

periodic() {
    # Run cleanup asynchronously to not block the prompt
    { _scratch_cleanup } &>/dev/null &!
}

# Run cleanup on shell exit (async to avoid blocking shell exit)
_scratch_zshexit() {
    { _scratch_cleanup } &>/dev/null &!
}

# Add to zshexit hooks
autoload -Uz add-zsh-hook
add-zsh-hook zshexit _scratch_zshexit
