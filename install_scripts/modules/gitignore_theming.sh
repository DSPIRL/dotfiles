#!/bin/env bash

cd $HOME/.local/share/chezmoi

git update-index --assume-unchanged ".config/alacritty/colors.toml" \
  ".config/ghostty/themes/wallust.conf" \
  ".config/hypr/monitors.conf" \
  ".config/hypr/themes/wallust.conf" \
  ".config/rofi/wallust/colors-rofi.rasi" \
  ".config/waybar/wallust/colors-wallust.css" \
  ".config/cava/themes/" \
  ".config/cava/shaders/"
