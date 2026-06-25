#!/usr/bin/env bash
set -euo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
  exit 0
fi

state_file="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/breeze-theme"
cursor_size="${BREEZE_CURSOR_SIZE:-24}"
mode="dark"

if [ -r "$state_file" ]; then
  IFS= read -r mode < "$state_file" || true
fi

case "$mode" in
  light)
    cursor_theme="Breeze_Light"
    color_preference="prefer-light"
    ;;
  *)
    cursor_theme="breeze_cursors"
    color_preference="prefer-dark"
    ;;
esac

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface color-scheme "$color_preference" >/dev/null 2>&1 || true
