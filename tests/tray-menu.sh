#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -m 700 "$sandbox/home" "$sandbox/runtime" "$sandbox/config" "$sandbox/cache" "$sandbox/data" "$sandbox/state"
cp "$root/tests/TrayMenuFixture.qml" "$sandbox/shell.qml"
cp -r "$root/dot_config/quickshell/default" "$sandbox/default"
# No display, compositor, inherited bus, or user XDG directories. The system bus is invalid.
if ! env -i PATH="$PATH" HOME="$sandbox/home" XDG_RUNTIME_DIR="$sandbox/runtime" XDG_CONFIG_HOME="$sandbox/config" \
  XDG_CACHE_HOME="$sandbox/cache" XDG_DATA_HOME="$sandbox/data" XDG_STATE_HOME="$sandbox/state" \
  DBUS_SYSTEM_BUS_ADDRESS="unix:path=$sandbox/no-system-bus" QT_QPA_PLATFORM=offscreen \
  timeout 12 dbus-run-session -- bash -c '
    /usr/bin/python3 "$1/tests/tray-menu-service.py" > "$2/service.log" 2>&1 &
    service=$!
    trap "kill $service 2>/dev/null || :; wait $service 2>/dev/null || :" EXIT
    quickshell -p "$2/shell.qml" --no-color > "$2/shell.log" 2>&1
  ' _ "$root" "$sandbox" \
  || ! grep -q TRAY_PASS "$sandbox/shell.log" \
  || grep -qE 'TRAY_FAIL|TypeError:|ReferenceError:|Failed to load configuration' "$sandbox/shell.log" \
  || ! /usr/bin/python3 - "$sandbox/service.log" <<'PY'
import sys
with open(sys.argv[1]) as log:
    events = [line.strip() for line in log if line.startswith('EVENT ')]
expected = ['EVENT 0 opened', 'EVENT 1 opened', 'EVENT 1 closed', 'EVENT 1 opened', 'EVENT 2 clicked',
            'EVENT 1 closed', 'EVENT 0 closed', 'EVENT 0 opened', 'EVENT 1 opened', 'EVENT 1 closed', 'EVENT 0 closed',
            'EVENT 0 opened', 'EVENT 0 closed']
if events != expected:
    print('Unexpected lifecycle:', events, file=sys.stderr)
    sys.exit(1)
PY
then
  echo 'Tray menu fixture failed:' >&2
  tail -n 80 "$sandbox/shell.log" "$sandbox/service.log" >&2
  exit 1
fi
echo 'Tray menu fixture passed (private bus, offscreen)'
