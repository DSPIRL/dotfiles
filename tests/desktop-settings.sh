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
  reload) printf 'reload\n' >>"$CALLS"; [[ "${FAIL_RELOAD:-0}" == 0 ]] ;;
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
cli blur enable
check blur enabled
calls=$(wc -l <"$CALLS")
cli blur enable
[[ $(wc -l <"$CALLS") == "$calls" ]]
cli low-effects enable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["blur"] and s["opacity"] and s["lowEffects"] and not s["effectiveBlur"] and not s["effectiveOpacity"]'
cli low-effects disable
cli status | python -c 'import json,sys; s=json.load(sys.stdin); assert s["effectiveBlur"] and s["effectiveOpacity"]'

if FAIL_RELOAD=1 cli blur disable; then echo 'Expected reload failure' >&2; exit 1; fi
check blur enabled
if CONFIG_ERROR='broken configuration' cli opacity disable; then echo 'Expected config failure' >&2; exit 1; fi
check opacity enabled
if CONFIG_QUERY_FAIL=1 cli blur disable; then echo 'Expected config query failure' >&2; exit 1; fi
check blur enabled
if cli status enable; then echo 'Expected invalid status argument rejection' >&2; exit 1; fi
if cli '../escape' enable; then echo 'Expected invalid argument rejection' >&2; exit 1; fi
[[ ! -e "$XDG_STATE_HOME/hypr/escape" ]]

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
echo 'Desktop preference checks passed'
