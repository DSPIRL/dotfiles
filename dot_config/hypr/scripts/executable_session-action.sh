#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == suspend && $# == 1 ]] || { printf 'Usage: %s suspend\n' "${0##*/}" >&2; exit 2; }
# hypridle's inhibit_sleep=3 waits for the Wayland lock before allowing sleep.
if ! command -v hyprlock >/dev/null || ! pgrep -u "$UID" -x hypridle >/dev/null; then
  printf 'Suspend requires hyprlock and a running hypridle lock-before-sleep service.\n' >&2
  exit 1
fi
systemctl suspend
