#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -z ${WAYLAND_DISPLAY:-} ]] || pgrep -u "$UID" -x hyprlock >/dev/null \
  || [[ $(loginctl show-session "${XDG_SESSION_ID:-self}" -p LockedHint --value 2>/dev/null) == yes ]]; then
  echo 'SKIP: full control-center fixture needs an unlocked Wayland session'
  exit 0
fi
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir "$sandbox/bin"
printf '#!/bin/sh\nprintf "synthetic-package 1 -> 2\\n"\n' > "$sandbox/bin/checkupdates"
chmod +x "$sandbox/bin/checkupdates"
cp -a "$root/dot_config/quickshell/default" "$sandbox/default"
cp "$sandbox/default/wallust/Colors.qml.tmpl" "$sandbox/default/wallust/Colors.qml"
cp "$root/tests/ControlCenterFixture.qml" "$sandbox/shell.qml"
# Native Wayland is required for PanelWindow; all service actions are mocked.
if ! PATH="$sandbox/bin:$PATH" QT_QPA_PLATFORM=wayland \
  timeout 12 quickshell -p "$sandbox/shell.qml" --no-color > "$sandbox/result.log" 2>&1 \
  || ! grep -q CONTROL_CENTER_PASS "$sandbox/result.log" || grep -qE 'CONTROL_CENTER_FAIL|TypeError:|ReferenceError:|Failed to load configuration' "$sandbox/result.log"; then
  tail -60 "$sandbox/result.log" >&2
  exit 1
fi
echo 'Control center checks passed: navigation, isolated settings, audio details, MPRIS capabilities, narrow layout, lifecycle and session guards'
