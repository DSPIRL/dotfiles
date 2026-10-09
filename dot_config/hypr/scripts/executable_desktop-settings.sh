#!/usr/bin/env bash
# Shared CLI for compositor preferences. Runtime state is deliberately outside chezmoi.
set -euo pipefail
umask 077
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/effects"
config_dir="${HOME}/.config/hypr/config"

usage() {
  printf 'Usage: %s status | {blur|opacity|low-effects} [status|enable|disable|toggle]\n' "${0##*/}" >&2
  exit 2
}

feature="${1:-status}"
case "$feature" in status|blur|opacity|low-effects) ;; *) usage ;; esac
operation="${2:-toggle}"
case "$operation" in status|enable|disable|toggle) ;; *) usage ;; esac
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

read_value() {
  local value
  read -r value <"$state_dir/$1" || true
  case "$value" in enabled|disabled) printf '%s' "$value" ;; *) printf 'Invalid preference: %s\n' "$1" >&2; return 1 ;; esac
}

boolean() { [[ "$1" == enabled ]] && printf true || printf false; }
available() { command -v "$1" >/dev/null 2>&1 && printf true || printf false; }

if [[ "$feature" == status ]]; then
  blur=$(read_value blur); opacity=$(read_value opacity); low=$(read_value low-effects)
  effective_blur=$blur; effective_opacity=$opacity
  if [[ "$low" == enabled ]]; then effective_blur=disabled; effective_opacity=disabled; fi
  theme=dark
  theme_file="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/breeze-theme"
  if [[ -r "$theme_file" ]] && [[ $(<"$theme_file") == light ]]; then theme=light; fi
  night=false; idle=false
  pgrep -u "$UID" -x hyprsunset >/dev/null 2>&1 && night=true
  pgrep -u "$UID" -x hypridle >/dev/null 2>&1 && idle=true
  printf '{"blur":%s,"opacity":%s,"lowEffects":%s,"effectiveBlur":%s,"effectiveOpacity":%s,"theme":"%s","nightLight":%s,"idleRunning":%s,"bluetoothSettings":%s,"networkSettings":%s,"nightLightAvailable":%s,"lockAvailable":%s}\n' \
    "$(boolean "$blur")" "$(boolean "$opacity")" "$(boolean "$low")" \
    "$(boolean "$effective_blur")" "$(boolean "$effective_opacity")" "$theme" "$night" "$idle" \
    "$(available blueman-manager)" "$(available nmtui)" "$(available hyprsunset)" "$(available hyprlock)"
  exit 0
fi

previous=$(read_value "$feature")
if [[ "$operation" == status ]]; then printf '%s\n' "$previous"; exit 0; fi
case "$operation" in
  enable) next=enabled ;;
  disable) next=disabled ;;
  toggle) if [[ "$previous" == enabled ]]; then next=disabled; else next=enabled; fi ;;
esac
if [[ "$previous" == "$next" ]]; then exit 0; fi

tmp=$(mktemp "$state_dir/.preference.XXXXXX")
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$next" >"$tmp"
mv -f "$tmp" "$state_dir/$feature"
if ! hyprctl reload >/dev/null || ! errors=$(hyprctl configerrors) || [[ -n "$errors" ]]; then
  printf '%s\n' "$previous" >"$state_dir/$feature"
  hyprctl reload >/dev/null 2>&1 || true
  printf 'Could not apply %s; restored previous preference.\n' "$feature" >&2
  exit 1
fi
