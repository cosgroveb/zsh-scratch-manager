# zsh-scratch-manager

A zsh plugin for creating temporary scratch directories with automatic cleanup.

```zsh
# .zshrc
bindkey '^S' scratch-widget
```

```zsh
$ # press Ctrl+S
~/scratch/tmp.x2Lm
$ # hack away
```

Or add an alias:

```zsh
# .zshrc
alias t='scratch'
```

```zsh
$ t myproject
~/scratch/myproject.x2Lm
```

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
scratch -l, --list       # List existing scratch directories
scratch -c, --cleanup    # Run cleanup now
scratch --help           # Show help
```

## Configuration

Set these environment variables before loading the plugin:

```zsh
export SCRATCH_DIR=~/scratch           # Where scratches are created
export SCRATCH_CLEANUP_PERIOD=3600     # Cleanup check interval (seconds)
export SCRATCH_CLEANUP_AGE=3600        # Min age before cleanup (seconds)
export SCRATCH_DEFAULT_PREFIX=tmp      # Default prefix when none given
```

## Aliases and Key Bindings

Add to your `.zshrc` after loading the plugin:

```zsh
alias t='scratch'
alias tt='scratch -t'
bindkey '^S' scratch-widget   # Ctrl+S to create scratch
```

## Auto-Cleanup

Abandoned scratch directories are cleaned up automatically in the background.

A directory is removed when ALL of these are true:

1. No visible files (empty or only hidden tool dirs)
2. No `.git` directory
3. No shell has it as current working directory
4. Older than `SCRATCH_CLEANUP_AGE`

## Features

- Random suffixes to avoid collisions
- Optional `/tmp` location for volatile scratch dirs
- Auto-cleanup of abandoned directories
- Tab completion
- Works with zinit, antibody, sheldon, oh-my-zsh, or direct sourcing

## License

MIT
