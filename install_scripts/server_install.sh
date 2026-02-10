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

if [[ "$operatingSystem" == "Arch Linux" ]]; then
    ##### USER CHOICES #####
    echo "
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
WHEN YOU GET TO THE OH-MY-ZSH INSTALL AND IT ASKS IF YOU WANT TO SET ZSH AS THE DEFAULT SHELL, ANSWER NO AND THEN TYPE \"exit\" TO CONTINUE THIS INSTALLATION
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

    sudo pacman -S $(awk -v RS= '{$1=$1}1' ~/.local/share/chezmoi/package_lists/archServerPackages.txt)

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    # ohmyzsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    rm -rf ~/.config/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.local/share/nvim

    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git

    chezmoi apply

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    cd $HOME
    sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si i

    yay -S carapace-bin

    ##### END USER CHOICES #####

    /usr/bin/zoxide init nushell >~/.zoxide.nu

    chsh -s /usr/bin/zsh
fi
