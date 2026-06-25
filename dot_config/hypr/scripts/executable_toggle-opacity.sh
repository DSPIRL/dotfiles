#!/usr/bin/env bash
set -euo pipefail

state_file="${HOME}/.config/hypr/config/opacity-toggle.lua"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Hyprland opacity" "$1"
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
  # notify "Configured opacity rules restored"
  exit 0
fi

write_state true
hyprctl reload >/dev/null
# notify "Opacity rules disabled"
