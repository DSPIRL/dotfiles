#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyprpicker >/dev/null 2>&1; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Color Picker" "hyprpicker is not installed"
  fi
  exit 1
fi

if pgrep -x hyprpicker >/dev/null 2>&1; then
  pkill -x hyprpicker || true
fi

color="$(hyprpicker || true)"
color="${color//$'\n'/}"

if [ -z "$color" ]; then
  exit 0
fi

if command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$color" | wl-copy
fi

cache_dir="$HOME/.cache/colorpicker"
cache_file="$cache_dir/colors"
mkdir -p "$cache_dir"
touch "$cache_file"

tmp_file="$(mktemp)"
{
  printf '%s\n' "$color"
  grep -Fxv "$color" "$cache_file" | head -n 9 || true
} > "$tmp_file"
mv "$tmp_file" "$cache_file"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Color Picker" "Copied $color to clipboard"
fi
