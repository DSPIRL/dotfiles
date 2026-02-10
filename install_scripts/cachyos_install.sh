#!/bin/env bash

#==============================================================#
# Define script location variable
DOTS="${HOME}/.local/share/chezmoi"
DOTPKG="${DOTS}/package_lists"
DOTSCRIPTS="${DOTS}/install_scripts"
DOTMODS="${DOTSCRIPTS}/modules"

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
cachyOs="CachyOS"

if [[ "$operatingSystem" == "$cachyOs" ]]; then
  read -rp 'Do you want to install LazyVim? (Y/N): ' varLazyVimInstall
  read -rp 'Do you want to install Syncthing? (Y/N): ' varSyncthingInstall

  if [[ "${chassis}" == "laptop" ]]; then
    read -rp 'Do you want to install Kanata for custom keyboard layouts? (Y/N): ' varKanataInstall
  fi

  # Rust
  # cd $HOME
  # curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  # LazyVim
  if [[ "${varLazyVimInstall^^}" == "Y" ]]; then
    bash -c "${DOTMODS}/lazyvim.sh"
  fi

  # Paru install
  bash -c "${DOTMODS}/paru.sh"

  # Default packages
  cd $HOME
  paru -S $(awk -v RS= '{$1=$1}1' ${DOTPKG}/cachyosPackages.txt) \
    $([[ "{varSyncthingInstall^^}" == "Y" ]] && echo syncthing) \
    $(echo carapace-bin)

  # Syncthing setup
  # if [[ "${varSyncthingInstall^^}" == "Y" ]]; then
  #   systemctl --user enable syncthing.service
  #   systemctl --user start syncthing.service
  # fi

  # Kanata install
  if [[ "${varKanataInstall^^}" == "Y" ]]; then
    ${HOME}/.cargo/bin/cargo install kanata
  fi

  # Link breeze cursors
  sudo ln -fvs "${DOTS}/assets/breeze_cursors" /usr/share/icons/

  # Zoxide setup
  /usr/bin/zoxide init nushell >~/.zoxide.nu

  # Change shell
  chsh -s /usr/bin/zsh

  # ohmyzsh install
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Apply dotfiles with chezmoi
  chezmoi apply
  bash -c "${DOTMODS}/gitignore_theming.sh"

  # SSH config setup
  bash -c "${DOTMODS}/ssh_config.sh"

  # Kill process
  kill $SUDO_KEEP_ALIVE_PID
fi
