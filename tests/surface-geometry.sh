#!/usr/bin/env bash
# Disposable virtual Wayland compositor only: never retain a live display/bus.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=SurfaceGeometryFixture.qml
tools=(quickshell kwin_wayland dbus-run-session bwrap)
case "${1:-}" in
  '') ;;
  --tray) fixture=TrayShadowFixture.qml; tools+=(cc pkg-config wayland-scanner /usr/bin/python3) ;;
  --workspaces) fixture=WorkspaceLifecycleFixture.qml; tools+=(Hyprland grim /usr/bin/python3) ;;
  *) echo "Usage: $0 [--tray|--workspaces]" >&2; exit 2 ;;
esac
for tool in "${tools[@]}"; do
  if ! command -v "$tool" >/dev/null; then echo "SKIP: surface geometry needs $tool"; exit 0; fi
done
if [[ $fixture == WorkspaceLifecycleFixture.qml ]]; then
  if ! /usr/bin/python3 -c 'import PIL.Image' 2>/dev/null; then echo 'SKIP: workspace pixels need Python Pillow'; exit 0; fi
  # Hyprland's instance signature must fit Unix socket path limits.
  sandbox=$(mktemp -d -t w.XXXXXX)
else
  sandbox=$(mktemp -d -t surface-geometry.XXXXXX)
fi
trap 'if [[ ${SURFACE_TEST_KEEP:-0} == 1 ]]; then echo "Probe artifacts: $sandbox"; else rm -rf "$sandbox"; fi' EXIT
mkdir -p "$sandbox"/{home,config,cache,data,state,runtime}
chmod 700 "$sandbox/runtime"
cp -a "$root/dot_config/quickshell/default" "$sandbox/default"
cp "$sandbox/default/wallust/Colors.qml.tmpl" "$sandbox/default/wallust/Colors.qml"
cp "$root/tests/$fixture" "$sandbox/shell.qml"
if [[ $fixture == TrayShadowFixture.qml ]]; then
  cp "$root/tests/tray-menu-service.py" "$sandbox/service.py"
  wayland-scanner client-header "$root/tests/kwin-fake-input.xml" "$sandbox/fake-input-client.h"
  wayland-scanner private-code "$root/tests/kwin-fake-input.xml" "$sandbox/fake-input-code.c"
  cc -Wall -Wextra -Werror "$root/tests/wayland-test-input.c" "$sandbox/fake-input-code.c" -I"$sandbox" \
    -o "$sandbox/input" $(pkg-config --cflags --libs wayland-client)
fi
# No service activation directories, even on this private session bus.
printf '<busconfig><type>session</type><listen>unix:tmpdir=%s</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>\n' \
  "$sandbox/runtime" > "$sandbox/bus.conf"
printf '#!/bin/sh\nexport QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=surface-test\ncd "%s"\n' "$sandbox" > "$sandbox/session"
if [[ $fixture == TrayShadowFixture.qml ]]; then
  printf 'export WAYLAND_DEBUG=1 SURFACE_TEST_INPUT="%s/input"\n/usr/bin/python3 service.py > service.log 2>&1 &\nservice=$!\ntrap '\''kill "$service" 2>/dev/null || :; wait "$service" 2>/dev/null || :'\'' EXIT\n' "$sandbox" >> "$sandbox/session"
fi
if [[ $fixture == WorkspaceLifecycleFixture.qml ]]; then
  mkdir -m 700 "$sandbox/r"
  printf '%s\n' \
    'hl.monitor({output="",mode="1280x900@60",position="auto",scale=1})' \
    'hl.config({animations={enabled=false},xwayland={enabled=false},misc={disable_hyprland_logo=true,disable_splash_rendering=true}})' \
    'hl.layer_rule({name="glass",match={namespace="^quickshell$"},blur=true,ignore_alpha=0.1})' \
    'hl.layer_rule({name="shadow",match={namespace="^quickshell-bar-shadow$"},order=1,blur=false,blur_popups=false,no_anim=true})' \
    "hl.on(\"hyprland.start\",function() hl.exec_cmd(\"$sandbox/client\") end)" > "$sandbox/hyprland.lua"
  printf '#!/bin/sh\ncd "%s"\nquickshell -p shell.qml --no-color > client.log 2>&1\ntouch done\n' "$sandbox" > "$sandbox/client"
  chmod +x "$sandbox/client"
  # Nest Hyprland inside the private KWin, never the user's compositor. Track
  # its own PID for teardown; no inherited signature or hyprctl is used.
  printf 'export WAYLAND_DISPLAY="%s/runtime/surface-test" XDG_RUNTIME_DIR="%s/r"\nHyprland -c "%s/hyprland.lua" > hyprland.log 2>&1 &\nhypr=$!\ntrap '\''kill "$hypr" 2>/dev/null || :; wait "$hypr" 2>/dev/null || :'\'' EXIT\nwhile kill -0 "$hypr" 2>/dev/null && [ ! -f done ]; do sleep .1; done\n' \
    "$sandbox" "$sandbox" "$sandbox" >> "$sandbox/session"
else
  printf 'quickshell -p shell.qml --no-color\n' >> "$sandbox/session"
fi
chmod +x "$sandbox/session"
# Render nodes permit offscreen GPU work, never DRM modesetting/card devices.
render_nodes=()
for node in /dev/dri/renderD*; do
  [[ -e $node ]] && render_nodes+=(--dev-bind "$node" "$node")
done
if (( ${#render_nodes[@]} == 0 )); then
  echo 'SKIP: virtual KWin geometry fixture needs a usable render node/OpenGL backend'
  exit 0
fi
result_log=$sandbox/result.log
[[ $fixture == WorkspaceLifecycleFixture.qml ]] && result_log=$sandbox/client.log
if ! env -i PATH=/usr/bin:/bin HOME="$sandbox/home" \
  XDG_CONFIG_HOME="$sandbox/config" XDG_CACHE_HOME="$sandbox/cache" \
  XDG_DATA_HOME="$sandbox/data" XDG_STATE_HOME="$sandbox/state" XDG_RUNTIME_DIR="$sandbox/runtime" \
  DBUS_SYSTEM_BUS_ADDRESS="unix:path=$sandbox/no-system-bus" \
  QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Basic QSG_RHI_BACKEND=opengl \
  LIBGL_ALWAYS_SOFTWARE=1 KWIN_COMPOSE=O2 LANG=C.UTF-8 \
  timeout --kill-after=2 120 bwrap --unshare-user --unshare-pid --unshare-ipc --unshare-net --die-with-parent \
    --ro-bind / / --tmpfs /tmp --tmpfs /run --bind "$sandbox" "$sandbox" --dev /dev --proc /proc "${render_nodes[@]}" \
    dbus-run-session --config-file="$sandbox/bus.conf" -- \
    kwin_wayland --virtual --width 1280 --height 900 --output-count 2 --socket surface-test \
    --no-lockscreen --no-global-shortcuts --no-kactivities --exit-with-session "$sandbox/session" \
    > "$sandbox/result.log" 2>&1 \
  || ! grep -q SURFACE_GEOMETRY_PASS "$result_log" \
  || grep -qE 'SURFACE_GEOMETRY_FAIL|TypeError:|ReferenceError:|Binding loop|Failed to load configuration' "$result_log"; then
  grep -E 'SURFACE_GEOMETRY_FAIL|TypeError:|ReferenceError:|Binding loop|Failed to load configuration' "$sandbox/result.log" >&2 || :
  tail -80 "$sandbox/result.log" >&2
  if [[ -f $sandbox/service.log ]]; then tail -30 "$sandbox/service.log" >&2; fi
  if [[ -f $sandbox/client.log ]]; then tail -40 "$sandbox/client.log" >&2; fi
  if [[ -f $sandbox/hyprland.log ]]; then tail -30 "$sandbox/hyprland.log" >&2; fi
  exit 1
fi
if [[ $fixture == WorkspaceLifecycleFixture.qml ]]; then
  /usr/bin/python3 - "$sandbox" <<'PY'
from pathlib import Path
import sys
from PIL import Image, ImageChops
root = Path(sys.argv[1])
def contour(path):
    with Image.open(path) as image:
        result = image.crop((0, 0, 120, 59)).convert('RGB')
    # Font rasterization can differ after animation; exclude only the glyph.
    # Retain the glass contour, old 84px silhouette and full shadow envelope.
    result.paste((0, 0, 0), (20, 12, 40, 32))
    return result
expected = contour(root / 'initial.png')
for cycle in range(12):
    actual = contour(root / f'settled-{cycle}.png')
    if ImageChops.difference(expected, actual).getbbox():
        raise SystemExit(f'FAIL: stale workspace shadow pixels after cycle {cycle}')
print('Workspace lifecycle passed: 12 production-pill add/activate/remove reversals, native frames/geometry and private Hyprland screenshot equality (no Qt grabs)')
PY
  grep 'WORKSPACE_LIFECYCLE_PROBE' "$result_log"
elif [[ $fixture == TrayShadowFixture.qml ]]; then
  grep 'TRAY_SHADOW_PROBE' "$sandbox/result.log"
  echo 'Tray shadow passed: production popup, private bus, disposable two-output Wayland; constraints, resize, first-frame/reset, suppression, Escape/outside dismissal and native fallback (not Hyprland pixel stacking/blur)'
else
  echo 'Surface geometry passed: disposable Wayland native buffers, glass-only masks, bar reveal/reservation, notification limits/timer/focus policy, resize/screens and shadow lifecycle (mock contents; not Hyprland stacking/pointer delivery)'
fi
