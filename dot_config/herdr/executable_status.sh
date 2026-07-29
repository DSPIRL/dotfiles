#!/bin/sh

printf 'Time: %s\n' "$(date '+%a %d %H:%M')"

battery=$(upower -e 2>/dev/null | awk '/battery/ { print; exit }')
if [ -n "$battery" ]; then
  details=$(upower -i "$battery" 2>/dev/null | awk -F: '
    /^[[:space:]]*(state|percentage|time to empty|time to full):/ {
      gsub(/^[[:space:]]+/, "", $2)
      printf "%s%s", separator, $2
      separator = " · "
    }
  ')
  printf 'Battery: %s\n' "${details:-unavailable}"
else
  printf 'Battery: unavailable\n'
fi

printf '\nPress Enter to close...'
IFS= read -r _
