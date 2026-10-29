#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
geometry_only=0
if [[ ${1:-} == --geometry-only ]]; then geometry_only=1
elif [[ $# != 0 ]]; then echo "Usage: $0 [--geometry-only]" >&2; exit 2; fi
if [[ -z ${WAYLAND_DISPLAY:-} ]] || pgrep -u "$UID" -x hyprlock >/dev/null \
  || [[ $(loginctl show-session "${XDG_SESSION_ID:-self}" -p LockedHint --value 2>/dev/null) == yes ]]; then
  echo 'SKIP: full control-center fixture needs an unlocked Wayland session'
  exit 0
fi
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox"/{bin,home,config,cache,data,state,runtime}
chmod 700 "$sandbox/runtime"
wayland_display=$WAYLAND_DISPLAY
[[ $wayland_display == /* ]] || wayland_display="${XDG_RUNTIME_DIR:?}/$wayland_display"
printf '#!/bin/sh\nprintf "synthetic-package 1 -> 2\\n"\n' > "$sandbox/bin/checkupdates"
chmod +x "$sandbox/bin/checkupdates"
cp -a "$root/dot_config/quickshell/default" "$sandbox/default"
cp "$sandbox/default/wallust/Colors.qml.tmpl" "$sandbox/default/wallust/Colors.qml"
cp "$root/tests/ControlCenterFixture.qml" "$sandbox/shell.qml"
# Only the Wayland socket is retained. No live buses, settings, shell IPC or
# compositor command environment; geometry-only avoids focus/actions and rapid
# reversal (one slow, unfocused close/reopen checks the paired surface lifecycle).
if ! env -i PATH="$sandbox/bin:/usr/bin:/bin" HOME="$sandbox/home" \
  XDG_CONFIG_HOME="$sandbox/config" XDG_CACHE_HOME="$sandbox/cache" \
  XDG_DATA_HOME="$sandbox/data" XDG_STATE_HOME="$sandbox/state" XDG_RUNTIME_DIR="$sandbox/runtime" \
  DBUS_SESSION_BUS_ADDRESS="unix:path=$sandbox/no-session-bus" \
  DBUS_SYSTEM_BUS_ADDRESS="unix:path=$sandbox/no-system-bus" \
  WAYLAND_DISPLAY="$wayland_display" QT_QPA_PLATFORM=wayland QT_QUICK_CONTROLS_STYLE=Basic \
  CONTROL_CENTER_GEOMETRY_ONLY="$geometry_only" \
  timeout 12 quickshell -p "$sandbox/shell.qml" --no-color > "$sandbox/result.log" 2>&1 \
  || ! grep -q CONTROL_CENTER_PASS "$sandbox/result.log" || grep -qE 'CONTROL_CENTER_FAIL|TypeError:|ReferenceError:|Failed to load configuration' "$sandbox/result.log"; then
  tail -60 "$sandbox/result.log" >&2
  exit 1
fi
if (( geometry_only )); then
  echo 'Control center geometry passed: glass frame/mask/layout preserved; separate shadow screen, padding, native size, input/focus policy, low-effects/zero-glass suppression and slow close/reopen; no focus/actions/rapid reversal'
else
  echo 'Control center checks passed: navigation, isolated settings, audio details, MPRIS capabilities, narrow layout, lifecycle and session guards'
fi
