#!/usr/bin/env bash
set -euo pipefail

defaults_file="$HOME/.config/hypr/config/defaults.conf"
search_engine="https://kagi.com/search?q={}"

if [[ -f "$defaults_file" ]]; then
  extracted="$(sed -n 's/^\$searchEngine[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$defaults_file" | head -n 1)"
  if [[ -n "$extracted" ]]; then
    search_engine="$extracted"
  fi
fi

if pgrep -x "rofi" >/dev/null; then
  pkill -x "rofi"
  exit 0
fi

rofi_theme="$HOME/.config/rofi/config-search.rasi"
query="$(printf '' | rofi -dmenu -config "$rofi_theme")"

if [[ -z "$query" ]]; then
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  encoded_query="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$query")"
else
  encoded_query="${query// /+}"
fi

if [[ "$search_engine" == *"{}"* ]]; then
  target_url="${search_engine//\{\}/$encoded_query}"
else
  target_url="$search_engine$encoded_query"
fi

xdg-open "$target_url" >/dev/null 2>&1 &
