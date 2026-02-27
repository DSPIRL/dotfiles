# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository supporting both **macOS** and **Arch Linux/CachyOS**. It was migrated from a Stow-based setup. The repository provides configurations for shell environments (Zsh, Bash, Nushell), editors (Neovim with LazyVim), terminal emulators, and on Linux, the Hyprland window manager with dynamic theming via Wallust.

## Common Commands

### Chezmoi Operations
```bash
chezmoi apply                    # Deploy dotfiles to home directory
chezmoi diff                     # Preview changes before applying
chezmoi edit <file>              # Edit a managed file
chezmoi add <file>               # Add a new file to management
chezmoi re-add                   # Re-add all modified files
```

### Installation Scripts
```bash
# Full Arch Linux + Hyprland setup (interactive)
./install_scripts/hyprland_install.sh

# CachyOS setup
./install_scripts/cachyos_install.sh

# Minimal server setup
./install_scripts/server_install.sh

# Individual modules (in install_scripts/modules/)
./install_scripts/modules/lazyvim.sh      # Clean LazyVim install
./install_scripts/modules/paru.sh         # Paru AUR helper
./install_scripts/modules/setup_git.sh    # Interactive git config
./install_scripts/modules/syncthing.sh    # Syncthing service setup
```

## Architecture

### Platform Separation
The `.chezmoiignore` file uses chezmoi templating to exclude platform-specific configs:
- **macOS only**: `aerospace/`, `karabiner/`
- **Linux only**: `hypr/`, `gtk-*`, `qt*ct/`, `quickshell/`, `rofi/`, `wal/`, `wallust/`, and other desktop configs

### Directory Structure
- `dot_config/` - XDG config files (40+ applications)
- `shell/` - Shared shell infrastructure (not deployed, sourced by shell configs)
  - `aliases.sh`, `custom_functions.sh`, `shellrc.sh` - Core shell setup
  - `zsh/macos.zsh`, `zsh/linux.zsh` - Platform-specific shell config
- `install_scripts/` - OS-specific installation scripts
- `package_lists/` - Package lists for different distros/setups

### Chezmoi Naming Conventions
- `dot_` prefix → dotfile (e.g., `dot_zshrc` → `.zshrc`)
- `empty_dot_` prefix → empty file placeholder
- `executable_` prefix → script with +x permission
- `private_` prefix → sensitive config (e.g., karabiner)

### Shell Configuration Chain
1. `.zshrc`/`.bashrc` sets `DOTS`, `DOTS_CONFIG`, `DOTS_SHELL` variables
2. Sources `shell/shellrc.sh` for environment variables and PATH
3. Sources `shell/aliases.sh` and `shell/custom_functions.sh`
4. Sources platform-specific file (`shell/zsh/macos.zsh` or `shell/zsh/linux.zsh`)

### Theme System (Linux)
Wallust generates dynamic colors for: Alacritty, Ghostty, Rofi, Quickshell, Swaync, Cava, GTK. The `install_scripts/modules/gitignore_theming.sh` script marks generated theme files as `--assume-unchanged` in git.

## Key Aliases
- `nv` - nvim
- `ls` - eza with icons (falls back to ls)
- `cd` - zoxide (if available)
- `cr`, `ct`, `cb` - cargo run/test/build
- `tms` - Start tmux session with preset windows
