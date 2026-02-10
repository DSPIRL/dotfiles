#!/bin/env bash

#==============================================================#
# Define script location variable
script_path="~/.local/share/chezmoi/install_scripts/"
dots_path="~/.local/share/chezmoi/"

# Sudo access
sudo echo "Sudo access granted for this script"
while true; do
    sudo -v
    sleep 240
done &

# Store the PID of the background process for this install script
SUDO_KEEP_ALIVE_PID=$!
#==============================================================#

operatingSystem=$(grep -i "PRETTY_NAME" </etc/os-release | awk -F'"' '{print $2}')
chassis=$(hostnamectl chassis)

if [[ "$operatingSystem" == "Arch Linux" ]]; then
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
        read -rp 'Would you like to install kanata for custom keyboard layouts? (Y/N): ' varInstallKanata
    fi

    echo ""
    echo '##### APPLICATIONS #####'
    read -rp 'Do you want to install Brave Browser? (Y/N): ' varInstallBraveBrowser
    read -rp 'Do you want to install LazyVim? (Y/N): ' varInstallLazyVim
    read -rp 'Do you want to install and setup Syncthing? (Y/N): ' varInstallSyncthing
    read -rp 'Do you want to install TMUX? (Y/N): ' varInstallTmux
    # read -rp 'Do you want to install Varia Download Manager? (Y/N): ' varInstallVaria
    # read -rp 'Do you want to install Easy Effects for Audio Manipulation? (Y/N): ' varInstallEasyEffects
    # read -rp 'Do you want to install Deluge bit-torrent manager? (Y/N): ' varInstallDeluge
    # read -rp 'Do you want to install Wireguard? (Y/N): ' varInstallWireguard
    # read -rp 'Do you want to install and setup Virtual Machines? (Y/N): ' varArchVM
    # read -rp 'Do you want to install Cryptomator? (Y/N): ' varInstallCryptomator
    # read -rp 'Do you want to install GIMP? (Y/N): ' varInstallGimp

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

    yes | sudo pacman -S curl

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    cd $HOME
    yes | sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si

    paru -S $(awk -v RS= '{$1=$1}1' ~/.local/share/chezmoi/package_lists/archPackages.txt) \
        $([[ "${varInstallSyncthing^^}" == "Y" ]] && echo syncthing) \
        $([[ ${varInstallTmux^^} == "Y" ]] && echo tmux) \
        $([[ ${varInstallWireguard^^} == "Y" ]] && echo wireguard-tools) \
        $([[ ${varArchVM^^} == "Y" ]] && awk -v RS= '{$1=$1}1' ~/.local/share/chezmoi/package_lists/archVMPackages.txt) \
        $([[ ${varInstallDeluge^^} == "Y" ]] && echo "deluge deluge-gtk") \
        $([[ ${chassis} == "laptop" && ${varInstallTLP^^} == "Y" ]] && echo "tlp")

    paru -S $(awk -v RS= '{$1=$1}1' ~/.local/share/chezmoi/package_lists/archHyprlandPackages.txt)
    paru -S $(awk -v RS= '{$1=$1}1' ~/.local/share/chezmoi/package_lists/archDevPackages.txt)

    # ohmyzsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [[ "${varInstallLazyVim^^}" == "Y" ]]; then
        rm -rf ~/.config/nvim
        rm -rf ~/.local/state/nvim
        rm -rf ~/.local/share/nvim

        git clone https://github.com/LazyVim/starter ~/.config/nvim
        rm -rf ~/.config/nvim/.git
    fi

    cd $HOME

    paru -S carapace-bin

    flatpak install flathub $([[ "${varInstallBraveBrowser^^}" == "Y" ]] && echo "com.brave.Browser") \
        $([[ "${varInstallVaria^^}" == "Y" ]] && echo "io.github.giantpinkrobots.varia") \
        $([[ "${varInstallEasyEffects^^}" == "Y" ]] && echo "com.github.wwmm.easyeffects") \
        $([[ "${varInstallHyprland^^}" == "Y" ]] && echo "it.mijorus.smile") \
        $([[ "${varInstallGimp}" == "Y" ]] && echo "org.gimp.GIMP") \
        $([[ "${varInstallCryptomator}" == "Y" ]] && echo "org.cryptomator.Cryptomator")

    if [[ "${varInstallBraveBrowser^^}" == "Y" ]]; then
        sudo ln -fvs /var/lib/flatpak/exports/bin/com.brave.Browser /usr/bin/brave
    fi

    if [[ "${varInstallVaria^^}" == "Y" ]]; then
        sudo ln -fvs /var/lib/flatpak/exports/bin/io.github.giantpinkrobots.varia /usr/bin/varia
    fi

    if [[ "${varInstallEasyEffects^^}" == "Y" ]]; then
        sudo ln -fvs /var/lib/flatpak/exports/bin/com.github.wwmm.easyeffects /usr/bin/easyeffects
    fi

    if [[ "${varInstallKanata^^}" == "Y" ]]; then
        $HOME/.cargo/bin/cargo install kanata
    fi

    if [[ "${varInstallSyncthing^^}" == "Y" ]]; then
        systemctl --user enable syncthing.service
        systemctl --user start syncthing.service
    fi

    ##### END USER CHOICES #####

    sudo ln -fvs ~/.local/share/chezmoi/assets/breeze_cursors /usr/share/icons/

    /usr/bin/zoxide init nushell >~/.zoxide.nu

    cd $HOME

    if [[ "${varInstallTmux^^}" == "Y" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    chsh -s /usr/bin/zsh

    if [[ "${varArchVM^^}" == "Y" ]]; then
        echo "Please review \"archVirtualizationInstruction.md\" to complete setup."
    fi

    chezmoi apply

    kill $SUDO_KEEPALIVE_PID
fi
