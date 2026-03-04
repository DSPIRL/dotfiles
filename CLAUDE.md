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
```

Individual component modules live under `install_scripts/modules/` and can be run independently.

## Architecture

### Platform Separation
The `.chezmoiignore` file uses chezmoi templating to exclude platform-specific configs:
- **macOS only**: `aerospace/`, `karabiner/`
- **Linux only**: `hypr/`, `gtk-*`, `qt*ct/`, `quickshell/`, `rofi/`, `wal/`, `wallust/`, and other desktop configs

### Directory Structure
- `dot_config/` - XDG config files (40+ applications)
- `private_dot_shell/` - Shared shell infrastructure deployed to `~/.shell/`; contains aliases, functions, and platform-specific shell snippets
- `install_scripts/` - OS-specific installation scripts
- `package_lists/` - Package lists for different distros/setups

### Chezmoi Naming Conventions
- `dot_` prefix → dotfile (e.g., `dot_zshrc` → `.zshrc`)
- `empty_dot_` prefix → empty file placeholder
- `executable_` prefix → script with +x permission
- `private_` prefix → sensitive config (e.g., karabiner)

### Shell Configuration Chain
1. `.zshrc`/`.bashrc` sources shared environment variables and PATH setup from `~/.shell/`
2. Sources shared aliases and functions from `~/.shell/`
3. Sources a platform-specific snippet (macOS or Linux) from `~/.shell/`
4. Sources any per-machine ZSH snippets from `~/.config/zsh/rc.d/`

### Theme System (Linux)
Wallust generates dynamic colors for: Alacritty, Ghostty, Rofi, Quickshell, Swaync, Cava, GTK. Generated theme files are marked `--assume-unchanged` in git so they are not tracked as changes.

## Key Aliases
- `nv` - nvim
- `ls` - eza with icons (falls back to ls)
- `cd` - zoxide (if available)
- `cr`, `ct`, `cb` - cargo run/test/build
- `tms` - Start tmux session with preset windows
