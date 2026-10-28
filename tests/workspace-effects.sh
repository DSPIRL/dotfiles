#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -m 700 "$sandbox/home" "$sandbox/runtime" "$sandbox/config" "$sandbox/cache" "$sandbox/data" "$sandbox/state"
cp -a "$root/dot_config/quickshell/default" "$sandbox/default"
cp "$root/tests/WorkspaceEffectsFixture.qml" "$sandbox/shell.qml"
# Quickshell embeds its QML plugins; qmltestrunner cannot load Hyprland here.
# Do not inherit display, compositor, bus, audio or user XDG sockets/settings.
# Invalid bus addresses also prevent D-Bus session autolaunch.
if ! env -i PATH="$PATH" HOME="$sandbox/home" XDG_RUNTIME_DIR="$sandbox/runtime" XDG_CONFIG_HOME="$sandbox/config" \
  XDG_CACHE_HOME="$sandbox/cache" XDG_DATA_HOME="$sandbox/data" XDG_STATE_HOME="$sandbox/state" \
  DBUS_SESSION_BUS_ADDRESS=unix:path="$sandbox/no-session-bus" \
  DBUS_SYSTEM_BUS_ADDRESS=unix:path="$sandbox/no-system-bus" \
  QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Basic \
  timeout 8 quickshell -p "$sandbox/shell.qml" --no-color > "$sandbox/result.log" 2>&1 \
  || ! grep -q WORKSPACE_PASS "$sandbox/result.log" \
  || grep -qE 'WORKSPACE_FAIL|TypeError:|ReferenceError:|Failed to load configuration' "$sandbox/result.log"; then
  tail -60 "$sandbox/result.log" >&2
  exit 1
fi
echo 'Workspace effects checks passed (offscreen)'
