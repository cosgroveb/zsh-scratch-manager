# zsh-scratch-manager

A zsh plugin for creating temporary scratch directories with automatic cleanup.

## Features

- Create scratch directories with random suffixes to avoid collisions
- Optional `/tmp` location for volatile scratch dirs
- Optional `HOME` isolation for testing tools with clean config
- Auto-cleanup of abandoned directories (configurable)
- Tab completion for flags and common prefixes
- Works with zinit, antibody, sheldon, oh-my-zsh, or direct sourcing

## Installation

### zinit

```zsh
zinit light cosgroveb/zsh-scratch-manager
```

### antibody

```zsh
antibody bundle cosgroveb/zsh-scratch-manager
```

### sheldon

```toml
[plugins.scratch-manager]
github = "cosgroveb/zsh-scratch-manager"
```

### oh-my-zsh

```bash
git clone https://github.com/cosgroveb/zsh-scratch-manager \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/scratch-manager
```

Then add `scratch-manager` to your plugins in `.zshrc`.

### Direct sourcing

```zsh
source /path/to/zsh-scratch-manager/scratch-manager.plugin.zsh
```

## Usage

```
scratch [prefix]         # Create ~/scratch/<prefix>.XXXX and cd into it
scratch -t [prefix]      # Create in /tmp (volatile, cleared on reboot)
scratch -H [prefix]      # Create with HOME set to scratch dir
scratch -tH [prefix]     # Both: /tmp + HOME isolation
scratch -l, --list       # List existing scratch directories
scratch -c, --cleanup    # Run cleanup now
scratch --help           # Show help
```

### Examples

```zsh
# Quick temporary directory
scratch
# -> Creates ~/scratch/tmp.a3Kf and cd's into it

# Named scratch for a specific task
scratch myproject
# -> Creates ~/scratch/myproject.x2Lm

# Volatile scratch that disappears on reboot
scratch -t experiment

# Isolated environment for testing tools
scratch -H tooltest
# -> Creates ~/scratch/tooltest.p4Qr with HOME set to it
# -> Tools like npm, cargo, etc. will use fresh configs

# Return to previous directory
popd
```

## Configuration

Set these environment variables before loading the plugin:

```zsh
# Where scratch directories are created (default: ~/scratch)
export SCRATCH_DIR=~/scratch

# How often to check for cleanup, in seconds (default: 3600 = 1 hour)
export SCRATCH_CLEANUP_PERIOD=3600

# Only clean directories older than this, in seconds (default: 3600)
export SCRATCH_CLEANUP_AGE=3600

# Default prefix when none specified (default: tmp)
export SCRATCH_DEFAULT_PREFIX=tmp
```

## Auto-Cleanup

The plugin automatically cleans up abandoned scratch directories:

- **When:** Every `SCRATCH_CLEANUP_PERIOD` seconds, and on shell exit
- **Async:** Cleanup runs in background to not block your prompt

### A directory is cleaned up if ALL of these are true:

1. No visible files (empty or only hidden tool dirs like `.local`, `.config`)
2. No `.git` directory (real projects are preserved)
3. No shell has it as current working directory
4. Older than `SCRATCH_CLEANUP_AGE`

### Preserved automatically:

- Directories with any visible files
- Git repositories (contain `.git`)
- Directories with user dotfiles (`.env`, `.envrc`, etc.)
- Directories currently in use by any shell

## License

MIT
