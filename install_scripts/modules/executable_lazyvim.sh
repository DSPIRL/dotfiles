#!/usr/bin/env bash

set -u

nvimDirs=(
    "${HOME}/.config/nvim"
    "${HOME}/.local/state/nvim"
    "${HOME}/.local/share/nvim"
)
existingDirs=()

for dir in "${nvimDirs[@]}"; do
    if [[ -e "${dir}" ]]; then
        existingDirs+=("${dir}")
    fi
done

if ((${#existingDirs[@]} > 0)); then
    echo "Existing Neovim files/directories were found:"
    printf '  %s\n' "${existingDirs[@]}"
    read -rp 'Delete them and install LazyVim? (Y/N): ' varDeleteNvim

    if [[ "${varDeleteNvim^^}" != "Y" ]]; then
        echo "Skipping LazyVim install."
        exit 0
    fi

    rm -rf "${existingDirs[@]}"
fi

if ! command -v git >/dev/null 2>&1; then
    sudo pacman -S --needed git
fi

mkdir -p "${HOME}/.config"
git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
rm -rf "${HOME}/.config/nvim/.git"
