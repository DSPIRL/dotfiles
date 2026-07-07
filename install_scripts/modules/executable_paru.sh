#!/usr/bin/env bash

set -u

if command -v paru >/dev/null 2>&1; then
    echo "paru is already installed."
    exit 0
fi

sudo pacman -S --needed git base-devel

if [[ -e "${HOME}/paru" && ! -d "${HOME}/paru/.git" ]]; then
    echo "Skipping paru install: ${HOME}/paru exists but is not a git checkout." >&2
    exit 1
fi

cd "${HOME}"

if [[ ! -d "${HOME}/paru/.git" ]]; then
    git clone https://aur.archlinux.org/paru.git "${HOME}/paru"
fi

cd "${HOME}/paru"
makepkg -si
