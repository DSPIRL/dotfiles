#!/usr/bin/env bash
set -euo pipefail

if pgrep -u "$UID" -x rofi >/dev/null; then
  pkill -u "$UID" -x rofi
  exit 0
fi

# Rofi's window mode does not enumerate native Hyprland windows.
windows="$(hyprctl -j clients | jq -c '
  [.[] | select(.mapped and .workspace != null)]
  | sort_by(.workspace.id, .class, .title)
')"
[[ "$windows" != '[]' ]] || exit 0

# Strip row separators/control bytes; titles are display data, never commands.
rows="$(jq -r '
  .[] | "[\(.workspace.name)] \(.class) — \(.title)"
  | gsub("[\u0000-\u001f\u007f]"; " ")
' <<<"$windows")"

# Original row indices distinguish windows even when their titles are identical.
selection="$(printf '%s\n' "$rows" | rofi -dmenu \
  -config "$HOME/.config/rofi/config.rasi" \
  -theme-str 'entry { placeholder: "Search open windows"; }' \
  -p Windows -i -matching fuzzy -no-custom -format i)" || exit 0
[[ "$selection" =~ ^[0-9]+$ ]] || exit 0

address="$(jq -r --argjson index "$selection" '.[$index].address // empty' <<<"$windows")"
[[ "$address" =~ ^0x[0-9a-fA-F]+$ ]] || exit 0

# A window may close while the menu is open. Focus also follows workspace changes.
hyprctl -j clients | jq -e --arg address "$address" \
  'any(.[]; .address == $address)' >/dev/null || exit 0
hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
