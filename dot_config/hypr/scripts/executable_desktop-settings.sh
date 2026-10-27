#!/usr/bin/env bash
# Shared CLI for desktop preferences. Runtime state is deliberately outside chezmoi.
set -euo pipefail
umask 077
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/effects"
config_dir="${HOME}/.config/hypr/config"

usage() {
  printf 'Usage: %s status | {blur|opacity|shell-glass|low-effects|monitor-resolution|night-light|keep-awake|quiet-notifications} [status|enable|disable|toggle] | {glass-opacity|control-opacity|window-opacity} [status|0..100] | blur-size [status|1..20]\n' "${0##*/}" >&2
  exit 2
}

is_numeric() {
  case "$1" in glass-opacity|control-opacity|window-opacity|blur-size) return 0 ;; *) return 1 ;; esac
}
valid_number() {
  [[ "$2" =~ ^(100|[1-9]?[0-9])$ ]] || return 1
  if [[ "$1" == blur-size ]]; then (( $2 >= 1 && $2 <= 20 )); fi
}

feature="${1:-status}"
case "$feature" in status|blur|opacity|shell-glass|low-effects|monitor-resolution|glass-opacity|control-opacity|window-opacity|blur-size|night-light|keep-awake|quiet-notifications) ;; *) usage ;; esac
operation="${2:-toggle}"
if is_numeric "$feature"; then
  operation="${2-status}"
  [[ "$operation" == status ]] || valid_number "$feature" "$operation" || usage
else
  case "$operation" in status|enable|disable|toggle) ;; *) usage ;; esac
fi
[[ $# -le 2 ]] || usage
[[ "$feature" != status || $# -le 1 ]] || usage

mkdir -p "$state_dir"
exec 9>"$state_dir/.lock"
flock 9

# Import the old live Lua flags once; they remain defaults for fresh installations.
for name in blur opacity low-effects; do
  if [[ ! -f "$state_dir/$name" ]]; then
    value=enabled
    case "$name" in
      blur) legacy=blur-toggle.lua ;;
      opacity) legacy=opacity-toggle.lua ;;
      low-effects) legacy=performance-profile.lua; value=disabled ;;
    esac
    if grep -Eq 'enabled[[:space:]]*=[[:space:]]*true' "$config_dir/$legacy" 2>/dev/null; then
      if [[ "$name" == low-effects ]]; then value=enabled; else value=disabled; fi
    fi
    printf '%s\n' "$value" >"$state_dir/$name"
  fi
done
for name in monitor-resolution shell-glass; do
  if [[ ! -f "$state_dir/$name" ]]; then
    printf '%s\n' enabled >"$state_dir/$name"
  fi
done

if [[ ! -f "$state_dir/glass-opacity" ]]; then
  # Preserve the percentage selected before this became a shell-wide setting.
  if [[ -f "$state_dir/control-center-opacity" ]]; then
    mv "$state_dir/control-center-opacity" "$state_dir/glass-opacity"
  else
    printf '%s\n' 40 >"$state_dir/glass-opacity"
  fi
fi

for name in control-opacity window-opacity blur-size; do
  if [[ ! -f "$state_dir/$name" ]]; then
    value=100
    [[ "$name" != blur-size ]] || value=3
    printf '%s\n' "$value" >"$state_dir/$name"
  fi
done

for name in night-light keep-awake quiet-notifications; do
  if [[ ! -f "$state_dir/$name" ]]; then
    value=disabled
    # Import an already-running night light without changing its current state.
    if [[ "$name" == night-light ]] && pgrep -u "$UID" -x hyprsunset >/dev/null 2>&1; then value=enabled; fi
    printf '%s\n' "$value" >"$state_dir/$name"
  fi
done

read_value() {
  local value
  read -r value <"$state_dir/$1" || true
  if is_numeric "$1"; then
    valid_number "$1" "$value" || { printf 'Invalid preference: %s\n' "$1" >&2; return 1; }
    printf '%s' "$value"
  else
    case "$value" in enabled|disabled) printf '%s' "$value" ;; *) printf 'Invalid preference: %s\n' "$1" >&2; return 1 ;; esac
  fi
}

boolean() { [[ "$1" == enabled ]] && printf true || printf false; }
available() { command -v "$1" >/dev/null 2>&1 && printf true || printf false; }

if [[ "$feature" == status ]]; then
  blur=$(read_value blur); opacity=$(read_value opacity); glass=$(read_value shell-glass); low=$(read_value low-effects)
  glass_opacity=$(read_value glass-opacity); control_opacity=$(read_value control-opacity)
  window_opacity=$(read_value window-opacity); blur_size=$(read_value blur-size)
  night_wanted=$(read_value night-light); awake=$(read_value keep-awake); quiet=$(read_value quiet-notifications)
  effective_blur=$blur; effective_opacity=$opacity; effective_glass=$glass
  if [[ "$low" == enabled ]]; then effective_blur=disabled; effective_opacity=disabled; effective_glass=disabled; fi
  effective_window_opacity=100
  [[ "$effective_opacity" != enabled ]] || effective_window_opacity=$window_opacity
  theme=dark
  theme_file="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/breeze-theme"
  if [[ -r "$theme_file" ]] && [[ $(<"$theme_file") == light ]]; then theme=light; fi
  night=false; idle=false
  pgrep -u "$UID" -x hyprsunset >/dev/null 2>&1 && night=true
  pgrep -u "$UID" -x hypridle >/dev/null 2>&1 && idle=true
  monitor_status=$(hyprctl repl 'return require("config.monitors").big_monitor_status()' 2>/dev/null || true)
  monitor_available=false
  [[ "$monitor_status" == wide || "$monitor_status" == compact ]] && monitor_available=true
  printf '{"blur":%s,"opacity":%s,"shellGlass":%s,"lowEffects":%s,"effectiveBlur":%s,"effectiveOpacity":%s,"effectiveShellGlass":%s,"glassOpacity":%s,"controlOpacity":%s,"windowOpacity":%s,"effectiveWindowOpacity":%s,"blurSize":%s,"theme":"%s","nightLight":%s,"nightLightWanted":%s,"keepAwake":%s,"quietNotifications":%s,"idleRunning":%s,"bluetoothSettings":%s,"networkSettings":%s,"nightLightAvailable":%s,"lockAvailable":%s,"bigMonitorAvailable":%s,"bigMonitorWide":%s}\n' \
    "$(boolean "$blur")" "$(boolean "$opacity")" "$(boolean "$glass")" "$(boolean "$low")" \
    "$(boolean "$effective_blur")" "$(boolean "$effective_opacity")" "$(boolean "$effective_glass")" \
    "$glass_opacity" "$control_opacity" "$window_opacity" "$effective_window_opacity" "$blur_size" "$theme" "$night" \
    "$(boolean "$night_wanted")" "$(boolean "$awake")" "$(boolean "$quiet")" "$idle" \
    "$(available blueman-manager)" "$(available nmtui)" "$(available hyprsunset)" "$(available hyprlock)" \
    "$monitor_available" "$([[ "$monitor_status" == wide ]] && printf true || printf false)"
  exit 0
fi

previous=$(read_value "$feature")
if [[ "$operation" == status ]]; then printf '%s\n' "$previous"; exit 0; fi
if is_numeric "$feature"; then
  next=$operation
else
  case "$operation" in
    enable) next=enabled ;;
    disable) next=disabled ;;
    toggle) if [[ "$previous" == enabled ]]; then next=disabled; else next=enabled; fi ;;
  esac
fi
# Reapplying night light also repairs a stopped daemon with an enabled preference.
if [[ "$previous" == "$next" && "$feature" != night-light ]]; then exit 0; fi

tmp=$(mktemp "$state_dir/.preference.XXXXXX")
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$next" >"$tmp"
mv -f "$tmp" "$state_dir/$feature"
apply_preference() {
  # Shell-only state is watched by Quickshell; never touch compositor/window rules.
  if [[ "$feature" == shell-glass || "$feature" == glass-opacity || "$feature" == control-opacity || "$feature" == keep-awake || "$feature" == quiet-notifications ]]; then return 0; fi
  if [[ "$feature" == night-light ]]; then
    # Only this CLI owns the preference; the helper applies it without writing it.
    # The parent retains its lock, but the helper/daemon must not inherit that fd.
    "${HOME}/.config/hypr/scripts/hyprsunset.sh" apply 9>&-
    return
  fi
  local result errors expected
  if [[ "$feature" == monitor-resolution ]]; then
    result=$(hyprctl repl 'require("config.monitors").apply(); return "monitors-applied"')
    expected=monitors-applied
  else
    result=$(hyprctl repl 'require("config.effects").apply(); return "effects-applied"')
    expected=effects-applied
  fi
  [[ "$result" == "$expected" ]] && errors=$(hyprctl configerrors) && [[ -z "$errors" ]] || return 1
  # Rofi parses its palette on launch; keep its solid fallback in sync.
  local theme_script="${HOME}/.config/hypr/scripts/toggle-breeze-theme.sh"
  if [[ "$feature" == low-effects && -x "$theme_script" ]]; then
    "$theme_script" refresh-shell 9>&-
  fi
}

if ! apply_preference; then
  printf '%s\n' "$previous" >"$state_dir/$feature"
  apply_preference >/dev/null 2>&1 || true
  printf 'Could not apply %s; restored previous preference.\n' "$feature" >&2
  exit 1
fi
