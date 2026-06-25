#!/usr/bin/env bash

set -u

cd "${HOME}/.local/share/chezmoi"

git update-index --assume-unchanged \
  "dot_config/alacritty/colors.toml" \
  "dot_config/ghostty/themes/wallust.conf" \
  "dot_config/hypr/themes/wallust.lua" \
  "dot_config/quickshell/wallust/Colors.qml" \
  "dot_config/rofi/wallust/colors-rofi.rasi" \
  "dot_config/swaync/wallust/colors-swaync.css" \
  "dot_config/cava/themes/" \
  "dot_config/cava/shaders/" 2>/dev/null || true
