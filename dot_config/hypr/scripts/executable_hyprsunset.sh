#!/usr/bin/env bash
set -euo pipefail
operation="${1:-toggle}"
case "$operation" in
  status) if pgrep -u "$UID" -x hyprsunset >/dev/null; then printf 'enabled\n'; else printf 'disabled\n'; fi; exit 0 ;;
  enable|disable|toggle) ;;
  *) printf 'Usage: %s [status|enable|disable|toggle]\n' "${0##*/}" >&2; exit 2 ;;
esac
active=false
pgrep -u "$UID" -x hyprsunset >/dev/null && active=true
if [[ "$operation" == toggle ]]; then
  if $active; then operation=disable; else operation=enable; fi
fi
if [[ "$operation" == disable ]]; then
  if $active; then pkill --signal INT -u "$UID" -x hyprsunset; fi
elif ! $active; then
  command -v hyprsunset >/dev/null
  hyprsunset -t 4000 >/dev/null 2>&1 &
  pid=$!
  sleep 0.3
  kill -0 "$pid" 2>/dev/null || { printf 'hyprsunset failed to start\n' >&2; exit 1; }
fi
