#!/usr/bin/env bash
# Isolated checks: no live compositor, theme, lock, or package commands are executed.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
export HOME="$sandbox/home with spaces" XDG_STATE_HOME="$sandbox/custom state"
mkdir -p "$HOME/.config/hypr/config" "$sandbox/bin"
export CALLS="$sandbox/calls"
printf 'return { enabled = true }\n' >"$HOME/.config/hypr/config/blur-toggle.lua"
printf 'return { enabled = false }\n' >"$HOME/.config/hypr/config/opacity-toggle.lua"
printf 'return { enabled = false }\n' >"$HOME/.config/hypr/config/performance-profile.lua"
cat >"$sandbox/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
  repl)
    printf 'repl %s\n' "$2" >>"$CALLS"
    [[ "${FAIL_APPLY:-0}" == 0 ]] || exit 1
    if [[ "${LUA_ERROR:-0}" == 1 ]]; then printf 'Lua error\n'; exit 0; fi
    case "$2" in
      'require("config.effects").apply(); return "effects-applied"') printf 'effects-applied\n' ;;
      'require("config.look_and_feel").apply_palette(); return "palette-applied"') printf 'palette-applied\n' ;;
      *) exit 2 ;;
    esac ;;
  configerrors) [[ "${CONFIG_QUERY_FAIL:-0}" == 0 ]] || exit 1; printf '%s' "${CONFIG_ERROR:-}" ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$sandbox/bin/hyprctl"
export PATH="$sandbox/bin:$PATH"
cli() { bash "$root/dot_config/hypr/scripts/executable_desktop-settings.sh" "$@"; }
check() { [[ $(cli "$1" status) == "$2" ]] || { echo "Unexpected $1 state" >&2; exit 1; }; }

check blur disabled
check opacity enabled
check shell-glass enabled
check glass-opacity 40
check control-opacity 100
check window-opacity 100
check blur-size 3
cli blur enable
check blur enabled
calls=$(wc -l <"$CALLS")
cli blur enable
[[ $(wc -l <"$CALLS") == "$calls" ]]
cli low-effects enable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["blur"] and s["opacity"] and s["shellGlass"] and s["lowEffects"] and not s["effectiveBlur"] and not s["effectiveOpacity"] and not s["effectiveShellGlass"]'
cli low-effects disable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["effectiveBlur"] and s["effectiveOpacity"] and s["effectiveShellGlass"]'

if FAIL_APPLY=1 cli blur disable; then echo 'Expected apply failure' >&2; exit 1; fi
check blur enabled
if LUA_ERROR=1 cli blur disable; then echo 'Expected Lua error rejection' >&2; exit 1; fi
check blur enabled
if CONFIG_ERROR='broken configuration' cli opacity disable; then echo 'Expected config failure' >&2; exit 1; fi
check opacity enabled
if CONFIG_QUERY_FAIL=1 cli blur disable; then echo 'Expected config query failure' >&2; exit 1; fi
check blur enabled
if cli status enable; then echo 'Expected invalid status argument rejection' >&2; exit 1; fi
if cli '../escape' enable; then echo 'Expected invalid argument rejection' >&2; exit 1; fi
[[ ! -e "$XDG_STATE_HOME/hypr/escape" ]]

# Glass is shell-only: neither window opacity nor backdrop blur owns its state.
cli opacity disable
cli blur disable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["effectiveShellGlass"] and not s["effectiveOpacity"] and not s["effectiveBlur"]'
# Even an unavailable compositor must not prevent saving a shell-only preference.
FAIL_APPLY=1 cli shell-glass disable
check shell-glass disabled
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert not s["shellGlass"] and not s["effectiveShellGlass"]'
calls=$(wc -l <"$CALLS")
cli shell-glass disable
cli shell-glass enable
check shell-glass enabled
[[ $(wc -l <"$CALLS") == "$calls" ]]
check blur disabled
check opacity disabled
cli low-effects enable
check shell-glass enabled
cli shell-glass disable
cli low-effects disable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert not s["shellGlass"] and not s["effectiveShellGlass"]'
cli shell-glass enable
cli opacity enable
cli blur enable
[[ $(stat -c %a "$XDG_STATE_HOME/hypr/effects/shell-glass") == 600 ]]

# Background opacity is a bounded, shell-only percentage, independent of buttons.
calls=$(wc -l <"$CALLS")
FAIL_APPLY=1 cli glass-opacity 0
check glass-opacity 0
cli glass-opacity 100
cli glass-opacity 100
[[ $(cli glass-opacity) == 100 ]]
[[ $(wc -l <"$CALLS") == "$calls" ]]
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert type(s["glassOpacity"]) is int and s["glassOpacity"] == 100'
for invalid in -1 101 01 1.5 enable toggle '' '1; echo unsafe'; do
  if cli glass-opacity "$invalid" 2>/dev/null; then
    echo "Expected invalid opacity rejection: $invalid" >&2; exit 1
  fi
done
check glass-opacity 100
cli low-effects enable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["glassOpacity"] == 100 and not s["effectiveShellGlass"]'
cli low-effects disable
cli glass-opacity 40
[[ $(stat -c %a "$XDG_STATE_HOME/hypr/effects/glass-opacity") == 600 ]]
printf 'invalid\n' >"$XDG_STATE_HOME/hypr/effects/glass-opacity"
if cli status >/dev/null 2>&1; then echo 'Expected corrupt opacity rejection' >&2; exit 1; fi
printf '40\n' >"$XDG_STATE_HOME/hypr/effects/glass-opacity"
check glass-opacity 40

# Import the previous control-center setting once; an existing global value wins.
mv "$XDG_STATE_HOME/hypr/effects/glass-opacity" "$XDG_STATE_HOME/hypr/effects/control-center-opacity"
printf '73\n' >"$XDG_STATE_HOME/hypr/effects/control-center-opacity"
check glass-opacity 73
[[ ! -e "$XDG_STATE_HOME/hypr/effects/control-center-opacity" ]]
printf '12\n' >"$XDG_STATE_HOME/hypr/effects/control-center-opacity"
check glass-opacity 73
rm "$XDG_STATE_HOME/hypr/effects/control-center-opacity"
cli glass-opacity 40

# Independent numeric settings: shell controls never call the compositor.
calls=$(wc -l <"$CALLS")
FAIL_APPLY=1 cli control-opacity 0
check control-opacity 0
cli control-opacity 61
check control-opacity 61
[[ $(wc -l <"$CALLS") == "$calls" ]]
cli window-opacity 0
check window-opacity 0
cli window-opacity 82
cli blur-size 1
cli blur-size 20
cli blur-size 7
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["glassOpacity"] == 40 and s["controlOpacity"] == 61 and s["windowOpacity"] == 82 and s["effectiveWindowOpacity"] == 82 and s["blurSize"] == 7'
for name in control-opacity window-opacity blur-size; do
  for invalid in -1 101 01 1.5 enable toggle '' '2; echo unsafe'; do
    if cli "$name" "$invalid" 2>/dev/null; then echo "Expected invalid $name rejection" >&2; exit 1; fi
  done
  [[ $(stat -c %a "$XDG_STATE_HOME/hypr/effects/$name") == 600 ]]
done
for invalid in 0 21 100; do
  if cli blur-size "$invalid" 2>/dev/null; then echo 'Expected out-of-range blur rejection' >&2; exit 1; fi
done
if FAIL_APPLY=1 cli window-opacity 65; then echo 'Expected window opacity rollback' >&2; exit 1; fi
check window-opacity 82
if LUA_ERROR=1 cli blur-size 9; then echo 'Expected blur size rollback' >&2; exit 1; fi
check blur-size 7
cli opacity disable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["windowOpacity"] == 82 and s["effectiveWindowOpacity"] == 100'
cli opacity enable
cli low-effects enable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["controlOpacity"] == 61 and s["windowOpacity"] == 82 and s["effectiveWindowOpacity"] == 100 and s["blurSize"] == 7 and not s["effectiveBlur"]'
cli low-effects disable
cli control-opacity 100
cli window-opacity 100
cli blur-size 3

# Applying managed defaults must not replace runtime preferences.
printf 'return { enabled = true }\n' >"$HOME/.config/hypr/config/opacity-toggle.lua"
check opacity enabled
cli blur toggle & first=$!
cli blur toggle & second=$!
wait "$first"; wait "$second"
check blur enabled

# The Lua consumer must agree with the CLI, including low-effects overrides.
export LUA_PATH="$root/dot_config/hypr/?.lua;;"
lua -e 'local e=require("config.effects"); assert(e.blur and e.opacity and not e.low_effects)'
cli low-effects enable
lua -e 'local e=require("config.effects"); assert(not e.blur and not e.opacity and e.low_effects)'
[[ $(stat -c %a "$XDG_STATE_HOME/hypr/effects/blur") == 600 ]]
# Empty XDG_STATE_HOME must fall back to HOME in both consumers.
XDG_STATE_HOME='' cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert not s["blur"] and not s["opacity"] and not s["lowEffects"]'
[[ -f "$HOME/.local/state/hypr/effects/blur" ]]
XDG_STATE_HOME='' lua -e 'local e=require("config.effects"); assert(not e.blur and not e.opacity and not e.low_effects)'
# Exercise actual Lua appearance updates with strict compositor doubles.
mkdir -p "$HOME/.config/hypr/themes"
printf 'return { color0="zero", color7="seven", color9="nine", color11="eleven", color12="twelve", color15="fifteen" }\n' >"$HOME/.config/hypr/themes/wallust.lua"
lua "$root/tests/appearance-runtime.lua"

# Wallpaper refresh must apply only colors, never reload the compositor.
for command in wallust pkill pgrep; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$sandbox/bin/$command"
  chmod +x "$sandbox/bin/$command"
done
HYPRLAND_INSTANCE_SIGNATURE=test bash "$root/dot_local/scripts/executable_wallust-refresh" wallpaper.png
[[ $(tail -n 1 "$CALLS") == 'repl require("config.look_and_feel").apply_palette(); return "palette-applied"' ]]
if HYPRLAND_INSTANCE_SIGNATURE=test LUA_ERROR=1 bash "$root/dot_local/scripts/executable_wallust-refresh" wallpaper.png; then
  echo 'Expected palette error rejection' >&2; exit 1
fi
calls=$(wc -l <"$CALLS")
HYPRLAND_INSTANCE_SIGNATURE='' bash "$root/dot_local/scripts/executable_wallust-refresh" wallpaper.png
[[ $(wc -l <"$CALLS") == "$calls" ]]
! grep -q '^reload' "$CALLS"
echo 'Desktop preference checks passed'
