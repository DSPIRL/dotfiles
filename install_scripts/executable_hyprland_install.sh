#!/usr/bin/env bash

set -u

#==============================================================#
# Define script location variables
DOTS="${HOME}/.local/share/chezmoi"
DOTPKG="${DOTS}/package_lists"
DOTSCRIPTS="${DOTS}/install_scripts"
DOTMODS="${DOTSCRIPTS}/modules"
#==============================================================#

run_module() {
    local module="$1"

    if [[ -f "${DOTMODS}/${module}" ]]; then
        bash "${DOTMODS}/${module}"
    elif [[ -f "${DOTMODS}/executable_${module}" ]]; then
        bash "${DOTMODS}/executable_${module}"
    else
        echo "Missing install module: ${module}" >&2
        return 1
    fi
}

install_packages() {
    local packages=("$@")

    if ((${#packages[@]} == 0)); then
        return 0
    fi

    if command -v paru >/dev/null 2>&1; then
        paru -S --needed "${packages[@]}"
    else
        echo "paru not found; using pacman for Hyprland packages."
        sudo pacman -S --needed "${packages[@]}"
    fi
}

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [[ "${ID:-}" != "cachyos" ]]; then
    echo "This installer is for CachyOS only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

cd "${HOME}"
mapfile -t hyprlandPackages < <(awk 'NF && $1 !~ /^#/ { print }' "${DOTPKG}/cachyosHyprlandPackages.txt")

install_packages "${hyprlandPackages[@]}"
run_module backlight.sh
run_module greetd.sh
