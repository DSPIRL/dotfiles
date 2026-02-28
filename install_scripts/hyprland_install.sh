#!/usr/bin/env bash

set -u

#==============================================================#
# Define script location variables
DOTS="${HOME}/.local/share/chezmoi"
DOTPKG="${DOTS}/package_lists"
DOTSCRIPTS="${DOTS}/install_scripts"
DOTMODS="${DOTSCRIPTS}/modules"
#==============================================================#

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [[ "${ID:-}" != "arch" ]]; then
    echo "This installer is for Arch Linux only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

chassis="$(hostnamectl chassis 2>/dev/null || true)"

varInstallTLP="N"
varInstallKanata="N"
varInstallBraveBrowser="N"
varInstallLazyVim="N"
varInstallSyncthing="N"
varInstallTmux="N"

##### USER CHOICES #####

echo '
  /$$$$$$  /$$                 /$$
 /$$__  $$| $$                |__/
| $$  \__/| $$$$$$$   /$$$$$$  /$$  /$$$$$$$  /$$$$$$   /$$$$$$$
| $$      | $$__  $$ /$$__  $$| $$ /$$_____/ /$$__  $$ /$$_____/
| $$      | $$  \ $$| $$  \ $$| $$| $$      | $$$$$$$$|  $$$$$$
| $$    $$| $$  | $$| $$  | $$| $$| $$      | $$_____/ \____  $$
|  $$$$$$/| $$  | $$|  $$$$$$/| $$|  $$$$$$$|  $$$$$$$ /$$$$$$$/
 \______/ |__/  |__/ \______/ |__/ \_______/ \_______/|_______/
'

echo ""
if [[ "${chassis}" == "laptop" ]]; then
    echo '##### LAPTOP SETUP #####'
    read -rp 'Do you want to install TLP for power management (ThinkPad Laptops)? (Y/N): ' varInstallTLP
    read -rp 'Would you like to install Kanata for custom keyboard layouts? (Y/N): ' varInstallKanata
fi

echo ""
echo '##### APPLICATIONS #####'
read -rp 'Do you want to install Brave Browser? (Y/N): ' varInstallBraveBrowser
read -rp 'Do you want to install LazyVim? (Y/N): ' varInstallLazyVim
read -rp 'Do you want to install and setup Syncthing? (Y/N): ' varInstallSyncthing
read -rp 'Do you want to install TMUX? (Y/N): ' varInstallTmux

echo "
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
WHEN YOU GET TO THE OH-MY-ZSH INSTALL AND IT ASKS IF YOU WANT TO SET ZSH AS THE DEFAULT SHELL, ANSWER NO AND THEN TYPE \"exit\" TO CONTINUE THIS INSTALLATION
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
sleep 5

echo '

/$$$$$$                       /$$               /$$ /$$
|_  $$_/                      | $$              | $$| $$
  | $$   /$$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$ | $$| $$
  | $$  | $$__  $$ /$$_____/|_  $$_/   |____  $$| $$| $$
  | $$  | $$  \ $$|  $$$$$$   | $$      /$$$$$$$| $$| $$
  | $$  | $$  | $$ \____  $$  | $$ /$$ /$$__  $$| $$| $$
/$$$$$$| $$  | $$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$| $$
|______/|__/  |__/|_______/    \___/   \_______/|__/|__/
'
sleep 2

# Sudo access
sudo echo "Sudo access granted for this script"
while true; do
    sudo -v
    sleep 240
done &

# Store the PID of the background process for this install script
SUDO_KEEP_ALIVE_PID=$!
trap 'kill "${SUDO_KEEP_ALIVE_PID}" >/dev/null 2>&1 || true' EXIT

yes | sudo pacman -S --needed curl base-devel

if ! command -v paru >/dev/null 2>&1; then
    cd "${HOME}"
    if [[ ! -d "${HOME}/paru/.git" ]]; then
        git clone https://aur.archlinux.org/paru.git "${HOME}/paru"
    fi
    cd "${HOME}/paru"
    makepkg -si
fi

cd "${HOME}"
paru -S $(awk -v RS= '{$1=$1}1' "${DOTPKG}/archPackages.txt") \
    $([[ "${varInstallSyncthing^^}" == "Y" ]] && echo syncthing) \
    $([[ "${varInstallTmux^^}" == "Y" ]] && echo tmux) \
    $([[ "${chassis}" == "laptop" && "${varInstallTLP^^}" == "Y" ]] && echo tlp)

paru -S $(awk -v RS= '{$1=$1}1' "${DOTPKG}/archHyprlandPackages.txt")
paru -S $(awk -v RS= '{$1=$1}1' "${DOTPKG}/archDevPackages.txt")

# ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [[ "${varInstallLazyVim^^}" == "Y" ]]; then
    rm -rf "${HOME}/.config/nvim"
    rm -rf "${HOME}/.local/state/nvim"
    rm -rf "${HOME}/.local/share/nvim"

    git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    rm -rf "${HOME}/.config/nvim/.git"
fi

if [[ "${varInstallBraveBrowser^^}" == "Y" ]]; then
    flatpak install flathub com.brave.Browser
    sudo ln -fvs /var/lib/flatpak/exports/bin/com.brave.Browser /usr/bin/brave
fi

if [[ "${varInstallKanata^^}" == "Y" ]]; then
    if ! command -v cargo >/dev/null 2>&1 && [[ ! -x "${HOME}/.cargo/bin/cargo" ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi

    if command -v cargo >/dev/null 2>&1; then
        cargo install kanata
    elif [[ -x "${HOME}/.cargo/bin/cargo" ]]; then
        "${HOME}/.cargo/bin/cargo" install kanata
    else
        echo "Skipping Kanata install: cargo is not available."
    fi
fi

if [[ "${varInstallSyncthing^^}" == "Y" ]]; then
    systemctl --user enable syncthing.service
    systemctl --user start syncthing.service
fi

if [[ -d "${DOTS}/assets/breeze_cursors" ]]; then
    sudo ln -fvs "${DOTS}/assets/breeze_cursors" /usr/share/icons/
else
    echo "Skipping custom breeze_cursors symlink (not found in assets/)."
fi

/usr/bin/zoxide init nushell >"${HOME}/.zoxide.nu"

if [[ "${varInstallTmux^^}" == "Y" && ! -d "${HOME}/.tmux/plugins/tpm/.git" ]]; then
    git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
fi

chsh -s /usr/bin/zsh

chezmoi apply
bash "${DOTMODS}/gitignore_theming.sh"
bash "${DOTMODS}/ssh_config.sh"
