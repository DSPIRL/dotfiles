#!/usr/bin/env bash
# Isolated CLI/process checks; no real night-light, inhibitor, lock, or session commands.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
sandbox=$(mktemp -d)
export HOME="$sandbox/home with spaces" XDG_STATE_HOME="$sandbox/state"
export NIGHT_PID="$sandbox/night.pid" NIGHT_STARTS="$sandbox/night.starts" NIGHT_ATTEMPTS="$sandbox/night.attempts"
export ALL_NIGHT_PIDS="$sandbox/all-night.pids"
# Disposable identity only: never connect to the real display, buses or state.
export HYPRLAND_INSTANCE_SIGNATURE=test-session-one WAYLAND_DISPLAY=not-a-real-display
export XDG_RUNTIME_DIR="$sandbox/runtime" XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$sandbox/cache" XDG_DATA_HOME="$sandbox/data"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/nonexistent/session-bus DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent/system-bus
unset DISPLAY
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export INHIBIT_PID="$sandbox/inhibit.pid" INHIBIT_CALLS="$sandbox/inhibit.calls" FAIL_INHIBIT="$sandbox/fail-inhibit"
cleanup() {
  if [[ -f "$ALL_NIGHT_PIDS" ]]; then
    while read -r child; do
      if grep -zFxq "NIGHT_ATTEMPTS=$NIGHT_ATTEMPTS" "/proc/$child/environ" 2>/dev/null; then
        kill -INT "$child" 2>/dev/null || true
      fi
    done <"$ALL_NIGHT_PIDS"
  fi
  if [[ -f "$INHIBIT_PID" ]]; then kill -TERM "$(<"$INHIBIT_PID")" 2>/dev/null || true; fi
  rm -rf "$sandbox"
}
trap cleanup EXIT
scripts="$HOME/.config/hypr/scripts"
mkdir -p "$scripts" "$HOME/.config/hypr/config" "$sandbox/bin"
cp "$root/dot_config/hypr/scripts/executable_desktop-settings.sh" "$scripts/desktop-settings.sh"
cp "$root/dot_config/hypr/scripts/executable_hyprsunset.sh" "$scripts/hyprsunset.sh"
chmod +x "$scripts"/*.sh
cat >"$sandbox/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
  repl) [[ "$2" == *'big_monitor_status()'* ]] && exit 0; printf 'effects-applied\n' ;;
  configerrors) ;;
  *) exit 2 ;;
esac
MOCK
cat >"$sandbox/bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
[[ "$*" == "-u $UID -x ${!#}" ]] || exit 2
case "${!#}" in
  hyprsunset)
    [[ -f "$ALL_NIGHT_PIDS" ]] || exit 1
    while read -r pid; do kill -0 "$pid" 2>/dev/null && printf '%s\n' "$pid"; done <"$ALL_NIGHT_PIDS"
    exit 0 ;;
  hypridle) [[ "${IDLE_RUNNING:-1}" == 1 ]] ;;
  *) exit 1 ;;
esac
MOCK
cat >"$sandbox/bin/pkill" <<'MOCK'
#!/usr/bin/env bash
[[ "$*" == "--signal INT -u $UID -x hyprsunset" ]] || exit 2
[[ -f "$NIGHT_PID" ]] && kill -INT "$(<"$NIGHT_PID")"
MOCK
cat >"$sandbox/bin/hyprsunset" <<'MOCK'
#!/usr/bin/env python3
import os, pathlib, signal, sys, time
with open(os.environ['NIGHT_ATTEMPTS'], 'a') as log:
    log.write('attempt\n')
if os.environ.get('FAIL_NIGHT') == '1' or os.environ.get('FAIL_TEMPERATURE') == sys.argv[-1]:
    sys.exit(1)
try:
    os.fstat(9)
except OSError:
    pass
else:
    sys.exit('A settings lock was inherited by the daemon')
assert sys.argv[1] == '-t' and len(sys.argv) == 3
assert 2500 <= int(sys.argv[2]) <= 6500
pid = pathlib.Path(os.environ['NIGHT_PID'])
pid.write_text(str(os.getpid()))
with open(os.environ['ALL_NIGHT_PIDS'], 'a') as log:
    log.write(str(os.getpid()) + '\n')
with open(os.environ['NIGHT_STARTS'], 'a') as log:
    log.write('start\n')
def stop(signum, frame):
    raise SystemExit(0)
signal.signal(signal.SIGINT, stop)
signal.signal(signal.SIGTERM, signal.SIG_IGN if os.environ.get('IGNORE_TERM') == '1' else stop)
try:
    while True:
        time.sleep(.02)
finally:
    pid.unlink(missing_ok=True)
MOCK
cat >"$sandbox/bin/systemd-inhibit" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$INHIBIT_CALLS"
[[ "$*" == '--what=idle --mode=block --who=Quickshell --why=Keep awake sh -c read -r _' ]] || exit 2
[[ ! -f "$FAIL_INHIBIT" ]] || exit 1
printf '%s\n' "$$" >"$INHIBIT_PID"
trap 'rm -f "$INHIBIT_PID"' EXIT
trap 'exit 0' TERM INT
while [[ "$1" == --* ]]; do shift; done
"$@"
MOCK
chmod +x "$sandbox/bin"/*
export PATH="$sandbox/bin:$PATH"
cli() { "$scripts/desktop-settings.sh" "$@"; }
check() { [[ $(cli "$1" status) == "$2" ]] || { echo "Unexpected $1 preference" >&2; exit 1; }; }
check night-light disabled
check keep-awake disabled
check quiet-notifications disabled
cli quiet-notifications enable
cli keep-awake enable
cli status | python3 -c 'import json,sys; s=json.load(sys.stdin); assert s["quietNotifications"] and s["keepAwake"] and not s["nightLightWanted"] and not s["nightLight"]'
[[ ! -f "$INHIBIT_PID" ]] # Saving desired state alone never launches an inhibitor.
cli quiet-notifications disable
cli keep-awake disable

# Night light uses the same persistent owner even through its old wrapper.
"$scripts/hyprsunset.sh" enable
check night-light enabled
[[ $("$scripts/hyprsunset.sh" status) == enabled ]]
cli night-light enable & enable_job=$!
"$scripts/hyprsunset.sh" apply & restore_job=$!
wait "$enable_job"; wait "$restore_job"
[[ $(wc -l <"$NIGHT_STARTS") == 1 ]]
# Both locks must be available even while the long-lived daemon is running.
timeout 2 "$scripts/desktop-settings.sh" status >/dev/null
timeout 2 "$scripts/hyprsunset.sh" apply
cli night-light disable
check night-light disabled
[[ ! -f "$NIGHT_PID" ]]
if FAIL_NIGHT=1 cli night-light enable; then echo 'Expected failed night-light launch' >&2; exit 1; fi
check night-light disabled
"$scripts/hyprsunset.sh" toggle
check night-light enabled
"$scripts/hyprsunset.sh" disable
# First use imports the on/off state, never a fictitious temperature or ownership.
rm "$XDG_STATE_HOME/hypr/effects/night-light"
hyprsunset -t 5300 </dev/null >/dev/null 2>&1 9>&- &
unmanaged_pid=$!
for _ in {1..20}; do [[ ! -f "$NIGHT_PID" ]] || break; sleep 0.05; done
check night-light enabled
[[ $("$scripts/hyprsunset.sh" temperature) == 0 ]]
if cli night-light disable 2>"$sandbox/unmanaged.log"; then echo 'Unmanaged daemon was taken over' >&2; exit 1; fi
grep -q 'unmanaged Night Light' "$sandbox/unmanaged.log"
kill -0 "$unmanaged_pid"
kill -TERM "$unmanaged_pid"
wait "$unmanaged_pid"
cli night-light disable

# Range validation, saved off-state temperature, and session-scoped ownership.
check night-light-temperature 4000
for invalid in 2499 6501 04000 4000.5 toggle '4000; true'; do
  if cli night-light-temperature "$invalid" 2>/dev/null; then exit 1; fi
done
cli night-light-temperature 6500
cli night-light enable
[[ $("$scripts/hyprsunset.sh" temperature) == 6500 ]]
cli night-light-temperature 2500
[[ $("$scripts/hyprsunset.sh" temperature) == 2500 ]]
# A second session on the same display cannot observe or signal our daemon.
first_pid=$(<"$NIGHT_PID")
HYPRLAND_INSTANCE_SIGNATURE=test-session-two "$scripts/hyprsunset.sh" apply
kill -0 "$first_pid" # apply uses shared enabled preference but launches its own daemon
second_pid=$(<"$NIGHT_PID")
[[ "$second_pid" != "$first_pid" ]]
HYPRLAND_INSTANCE_SIGNATURE=test-session-two cli night-light disable
kill -0 "$first_pid"
if kill -0 "$second_pid" 2>/dev/null; then echo 'Second session did not stop' >&2; exit 1; fi
cli night-light disable
cli night-light-temperature 4000
cli night-light enable
# A failed temperature restart restores the old value AND the old runtime state.
if FAIL_TEMPERATURE=3500 cli night-light-temperature 3500; then exit 1; fi
check night-light-temperature 4000
[[ $("$scripts/hyprsunset.sh" temperature) == 4000 ]]
# If rollback also fails, report that runtime restoration is unconfirmed.
if FAIL_NIGHT=1 cli night-light-temperature 3500 2>"$sandbox/rollback.log"; then exit 1; fi
grep -q 'runtime state is unconfirmed' "$sandbox/rollback.log"
check night-light-temperature 4000
[[ $("$scripts/hyprsunset.sh" status) == disabled ]]
cli night-light enable
# A tampered/stale record must not authorize signalling an existing process.
record=$(find "$XDG_STATE_HOME/hypr/effects/night-light-sessions" -name daemon | head -n 1)
cp "$record" "$sandbox/record.backup"
read -r owned_pid start temperature token <"$record"
printf '%s %s %s wrong-token\n' "$owned_pid" "$start" "$temperature" >"$record"
if cli night-light disable 2>/dev/null; then echo 'Stale ownership accepted' >&2; exit 1; fi
kill -0 "$owned_pid"
cp "$sandbox/record.backup" "$record"
cli night-light disable
# An unidentified legacy daemon is not assumed to belong to a different session.
env -u HYPRLAND_INSTANCE_SIGNATURE hyprsunset -t 5300 </dev/null >/dev/null 2>&1 &
legacy_pid=$!
for _ in {1..20}; do [[ ! -f "$NIGHT_PID" ]] || break; sleep 0.05; done
if cli night-light enable 2>/dev/null; then echo 'Unidentified daemon ignored' >&2; exit 1; fi
kill -0 "$legacy_pid"
kill -TERM "$legacy_pid"
wait "$legacy_pid"
# A daemon that refuses to stop cannot be replaced; the old preference survives.
IGNORE_TERM=1 cli night-light enable
stuck_pid=$(<"$NIGHT_PID")
if cli night-light disable 2>"$sandbox/stuck.log"; then exit 1; fi
grep -q 'did not stop' "$sandbox/stuck.log"
check night-light enabled
kill -0 "$stuck_pid"
kill -INT "$stuck_pid"
for _ in {1..20}; do [[ -f "$NIGHT_PID" ]] || break; sleep 0.05; done
cli night-light disable
if env -u HYPRLAND_INSTANCE_SIGNATURE "$scripts/hyprsunset.sh" apply 2>/dev/null; then exit 1; fi
for name in night-light night-light-temperature keep-awake quiet-notifications; do
  [[ $(stat -c %a "$XDG_STATE_HOME/hypr/effects/$name") == 600 ]]
done

if [[ ${CLI_ONLY:-0} == 1 ]]; then echo 'Session CLI checks passed'; exit 0; fi

# Extract the production inhibitor owner without starting the real notification
# server or any bar windows. Each launch is a fresh Quickshell process.
python3 - "$root" "$sandbox" <<'PY'
import pathlib, sys
root, sandbox = map(pathlib.Path, sys.argv[1:])
source = (root / 'dot_config/quickshell/default/shell.qml').read_text()
desktop = '  DesktopState { id: desktopSettings }\n'
assert desktop in source
start = source.index('  // systemd idle inhibition')
end = source.index('  readonly property string ddcBrightnessCommand', start)
owner = desktop + source[start:end]
bar_source = (root / 'dot_config/quickshell/default/components/BarWindow.qml').read_text()
toast_start = bar_source.index('  function showNotificationToast(')
toast_end = bar_source.index('  function clearNotifications(', toast_start)
toast_guard = bar_source[toast_start:toast_end]
imports = '''import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "file://''' + str(root / 'dot_config/quickshell/default/components/control') + '''"
ShellRoot {
'''
tests = '''
  property var desktopState: desktopSettings
  property var toastNotification
  property bool toastVisible: false
  property bool startupGuardPassed: false
  function isFocusedMonitor() { return true; }
  function notificationToastDuration(notification) { return 5500; }
  Timer { id: toastTimer }
  Component.onCompleted: {
    showNotificationToast({urgency: NotificationUrgency.Normal});
    const normalSuppressed = !toastVisible;
    showNotificationToast({urgency: NotificationUrgency.Critical});
    startupGuardPassed = normalSuppressed && toastVisible;
    toastVisible = false;
  }
  Timer {
    running: true
    interval: 500
    onTriggered: {
      if (Quickshell.env("SCENARIO") === "write") {
        desktopSettings.run(["sh", "-c", "sleep 0.3"]);
        desktopSettings.setNumericSetting("glass-opacity", 23);
        desktopSettings.setQuiet(true);
        desktopSettings.setKeepAwake(true);
      } else if (Quickshell.env("SCENARIO") === "restore") {
        desktopSettings.setKeepAwake(false);
        desktopSettings.setKeepAwake(true);
      }
    }
  }
  Timer {
    running: true
    interval: 1600
    onTriggered: {
      const scenario = Quickshell.env("SCENARIO");
      const enabled = scenario !== "disabled";
      let valid = startupGuardPassed && desktopSettings.loaded && desktopSettings.quiet === enabled && desktopSettings.keepAwakeRequested === enabled;
      toastVisible = false;
      showNotificationToast({urgency: NotificationUrgency.Normal});
      valid = valid && toastVisible === !enabled;
      showNotificationToast({urgency: NotificationUrgency.Critical});
      valid = valid && toastVisible;
      toastVisible = false;
      valid = valid && desktopSettings.values.quietNotifications === enabled && desktopSettings.values.keepAwake === enabled;
      valid = valid && desktopSettings.glassOpacity === 23 && desktopSettings.values.glassOpacity === 23;
      valid = valid && Object.keys(desktopSettings.pendingSettings).length === 0 && !desktopSettings.busy;
      if (scenario === "failure")
        valid = valid && !desktopSettings.keepAwake && desktopSettings.keepAwakeFailed && !awakeProcess.running;
      else valid = valid && desktopSettings.keepAwake === enabled && !desktopSettings.keepAwakeFailed && awakeProcess.running === enabled;
      if (scenario === "disabled")
        valid = valid && !desktopSettings.values.nightLightWanted && !desktopSettings.values.nightLight;
      else if (scenario !== "write")
        valid = valid && desktopSettings.values.nightLightWanted && (scenario === "night-failure" ? !desktopSettings.values.nightLight && desktopSettings.error.length > 0 : desktopSettings.values.nightLight);
      if (valid) console.log("SESSION_TEST_PASS: " + scenario);
      else console.error("SESSION_TEST_FAIL: " + scenario + " " + desktopSettings.error);
      Qt.quit();
    }
  }
}
'''
(sandbox / 'shell.qml').write_text(imports + owner + toast_guard + tests)
PY
run_shell() {
  SCENARIO="$1" QT_QPA_PLATFORM=offscreen timeout 8 quickshell -p "$sandbox/shell.qml" --no-color >"$sandbox/$1.log" 2>&1 || {
    local status=$?
    printf 'Quickshell scenario %s exited %s:\n' "$1" "$status" >&2
    while IFS= read -r line; do printf '%s\n' "$line" >&2; done <"$sandbox/$1.log"
    return "$status"
  }
  grep -q "SESSION_TEST_PASS: $1" "$sandbox/$1.log" || { grep -E 'ERROR|WARN|SESSION_TEST' "$sandbox/$1.log" >&2 || true; exit 1; }
  sleep 0.1
  if [[ -f "$INHIBIT_PID" ]]; then
    ! kill -0 "$(<"$INHIBIT_PID")" 2>/dev/null || { echo 'Inhibitor survived shell exit' >&2; exit 1; }
    rm -f "$INHIBIT_PID"
  fi
  local expected=enabled
  [[ "$1" != disabled ]] || expected=disabled
  check quiet-notifications "$expected"
  check keep-awake "$expected"
  check glass-opacity 23
}
run_shell write
# Simulate a reboot: preferences remain, but the night-light daemon has gone.
cli night-light enable
kill -INT "$(<"$NIGHT_PID")"
for _ in {1..20}; do [[ -f "$NIGHT_PID" ]] || break; sleep 0.05; done
IDLE_RUNNING=0 run_shell restore # Restoration must not race a late hypridle startup.
check night-light enabled
[[ -f "$NIGHT_PID" ]] && kill -0 "$(<"$NIGHT_PID")"
# An inhibitor failure must not turn a saved enabled preference into disabled.
touch "$FAIL_INHIBIT"
calls=$(wc -l <"$INHIBIT_CALLS")
run_shell failure
[[ $(wc -l <"$INHIBIT_CALLS") == $((calls + 1)) ]]
rm "$FAIL_INHIBIT"
kill -INT "$(<"$NIGHT_PID")"
for _ in {1..20}; do [[ -f "$NIGHT_PID" ]] || break; sleep 0.05; done
attempts=$(wc -l <"$NIGHT_ATTEMPTS")
FAIL_NIGHT=1 run_shell night-failure
check night-light enabled
[[ $(wc -l <"$NIGHT_ATTEMPTS") == $((attempts + 1)) ]]
[[ ! -f "$NIGHT_PID" ]]
cli night-light disable
cli keep-awake disable
cli quiet-notifications disable
calls=$(wc -l <"$INHIBIT_CALLS")
run_shell disabled
[[ $(wc -l <"$INHIBIT_CALLS") == "$calls" ]]
echo 'Session preferences passed: on/off cold restore, quiet/critical startup handling, rapid toggles, failure retention, session-owned temperature/range/migration/stale-record/stop-timeout/rollback checks, and idle-only cleanup'
