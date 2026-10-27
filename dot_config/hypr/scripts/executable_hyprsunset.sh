#!/usr/bin/env bash
set -euo pipefail
umask 077
operation="${1:-toggle}"
[[ $# -le 1 ]] || { printf 'Expected one night-light operation\n' >&2; exit 2; }
case "$operation" in
  status) if pgrep -u "$UID" -x hyprsunset >/dev/null; then printf 'enabled\n'; else printf 'disabled\n'; fi; exit 0 ;;
  enable|disable|toggle)
    exec "${HOME}/.config/hypr/scripts/desktop-settings.sh" night-light "$operation"
    ;;
  apply) ;;
  *) printf 'Usage: %s [status|enable|disable|toggle|apply]\n' "${0##*/}" >&2; exit 2 ;;
esac

# This runtime-only path is also called once after Quickshell restores settings.
# Serialize startup restoration and manual toggles, reading the latest preference.
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/effects"
mkdir -p "$state_dir"
exec 9>"$state_dir/.night-light.lock"
flock 9
wanted=""
read -r wanted <"$state_dir/night-light" || true
case "$wanted" in enabled|disabled) ;; *) printf 'Invalid night-light preference\n' >&2; exit 1 ;; esac
active=false
pgrep -u "$UID" -x hyprsunset >/dev/null && active=true

if [[ "$wanted" == disabled ]]; then
  if ! $active; then exit 0; fi
  if ! pkill --signal INT -u "$UID" -x hyprsunset && pgrep -u "$UID" -x hyprsunset >/dev/null; then
    printf 'Could not stop hyprsunset\n' >&2; exit 1
  fi
  for _ in {1..20}; do
    if ! pgrep -u "$UID" -x hyprsunset >/dev/null; then exit 0; fi
    sleep 0.05
  done
  printf 'hyprsunset did not stop\n' >&2
  exit 1
fi
if $active; then exit 0; fi
command -v hyprsunset >/dev/null
# A long-lived daemon must not retain either the preference lock or our stdio.
hyprsunset -t 4000 </dev/null >/dev/null 2>&1 9>&- &
pid=$!
sleep 0.3
kill -0 "$pid" 2>/dev/null || { printf 'hyprsunset failed to start\n' >&2; exit 1; }
