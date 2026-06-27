#!/usr/bin/env bash
set -euo pipefail

state_file="${HOME}/.config/hypr/config/performance-profile.lua"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Hyprland performance profile" "$1"
  fi
}

write_state() {
  local enabled="$1"

  mkdir -p "$(dirname "$state_file")"
  printf 'return {\n  enabled = %s,\n}\n' "$enabled" > "$state_file"
}

if [ -r "$state_file" ] && grep -Eq 'enabled[[:space:]]*=[[:space:]]*true' "$state_file"; then
  write_state false
  hyprctl reload >/dev/null
  notify "Disabled: restored animations, blur, shadows, and configured opacity"
  exit 0
fi

write_state true
hyprctl reload >/dev/null
notify "Enabled: disabled loop border angle, animations, blur, shadows, and opacity"
