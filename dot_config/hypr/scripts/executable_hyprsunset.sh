#!/usr/bin/env bash
# Only manage daemons launched by this helper in this Hyprland session.
set -euo pipefail
umask 077
operation="${1:-toggle}"
[[ $# -le 1 ]] || exit 2
case "$operation" in
  enable|disable|toggle)
    exec "${HOME}/.config/hypr/scripts/desktop-settings.sh" night-light "$operation" ;;
  status|temperature|apply) ;;
  *) printf 'Usage: %s [status|temperature|enable|disable|toggle|apply]\n' "${0##*/}" >&2; exit 2 ;;
esac

state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/effects"
# A display name alone can be reused across logins. Require the compositor identity.
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || -z "${WAYLAND_DISPLAY:-}" ]]; then
  case "$operation" in
    status) printf 'disabled\n'; exit 0 ;;
    temperature) printf '0\n'; exit 0 ;;
  esac
  printf 'Night light requires a Hyprland session identity and Wayland display\n' >&2
  exit 1
fi
session=$(printf '%s\0%s\0%s' "$HYPRLAND_INSTANCE_SIGNATURE" "$WAYLAND_DISPLAY" "${XDG_RUNTIME_DIR:-}" | sha256sum)
session=${session%% *}
session_dir="$state_dir/night-light-sessions/$session"
record="$session_dir/daemon"

# /proc start time plus a random, launch-only environment token protects against
# stale records and PID reuse. A name or a same-UID PID is never ownership proof.
process_start() {
  local stat rest
  [[ -r "/proc/$1/stat" ]] || return 1
  IFS= read -r stat <"/proc/$1/stat" || return 1
  rest=${stat##*) }
  local -a fields
  read -r -a fields <<<"$rest"
  [[ ${fields[0]} != Z && ${fields[0]} != X ]] || return 1
  printf '%s' "${fields[19]}"
}
has_environment() {
  grep -zFxq -- "$2" "/proc/$1/environ" 2>/dev/null
}
pid=0; started=0; temperature=0; token=''
load_owned() {
  [[ -r "$record" ]] || return 1
  read -r pid started temperature token <"$record" || return 1
  [[ "$pid" =~ ^[1-9][0-9]*$ && "$started" =~ ^[0-9]+$ && "$temperature" =~ ^[0-9]{4}$ && -n "$token" ]] || return 1
  [[ $(process_start "$pid") == "$started" ]] || return 1
  has_environment "$pid" "QUICKSHELL_NIGHT_LIGHT_OWNER=$session:$token"
}
unmanaged=false
find_unmanaged() {
  local candidate
  while read -r candidate; do
    [[ "$candidate" =~ ^[1-9][0-9]*$ ]] || continue
    process_start "$candidate" >/dev/null || continue
    # If an old daemon has no readable compositor identity, do not guess that
    # it belongs elsewhere and risk starting a competing gamma controller.
    if ! grep -zq '^HYPRLAND_INSTANCE_SIGNATURE=.' "/proc/$candidate/environ" 2>/dev/null ||
       has_environment "$candidate" "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"; then
      unmanaged=true
      return
    fi
  done < <(pgrep -u "$UID" -x hyprsunset || true)
}

if [[ "$operation" != apply ]]; then
  if load_owned; then
    if [[ "$operation" == status ]]; then printf 'enabled\n'; else printf '%s\n' "$temperature"; fi
  elif [[ "$operation" == temperature ]]; then
    printf '0\n'
  else
    find_unmanaged
    if $unmanaged; then printf 'enabled\n'; else printf 'disabled\n'; fi
  fi
  exit 0
fi

mkdir -p "$session_dir"
exec 9>"$session_dir/lock"
flock 9
wanted=''; desired=''
read -r wanted <"$state_dir/night-light" || true
read -r desired <"$state_dir/night-light-temperature" || true
case "$wanted" in enabled|disabled) ;; *) printf 'Invalid night-light preference\n' >&2; exit 1 ;; esac
[[ "$desired" =~ ^[0-9]{4}$ ]] && (( desired >= 2500 && desired <= 6500 )) || { printf 'Invalid night-light temperature\n' >&2; exit 1; }
owned=false
if load_owned; then owned=true; fi
if ! $owned; then
  find_unmanaged
  if $unmanaged; then
    printf 'An unmanaged Night Light daemon belongs to this session or has no verifiable session identity; stop it manually before using these controls. Its temperature has not been changed.\n' >&2
    exit 1
  fi
fi
if $owned; then
  if [[ "$wanted" == enabled && "$temperature" == "$desired" ]]; then exit 0; fi
  # Recheck identity immediately before signalling; never use broad pkill.
  if load_owned; then kill -TERM "$pid"; fi
  for _ in {1..40}; do
    if ! load_owned; then break; fi
    sleep 0.05
  done
  if load_owned; then printf 'Session Night Light daemon did not stop\n' >&2; exit 1; fi
fi
rm -f "$record"
[[ "$wanted" == enabled ]] || exit 0
command -v hyprsunset >/dev/null
read -r token </proc/sys/kernel/random/uuid
# No preference/session lock or command streams may leak into the daemon.
QUICKSHELL_NIGHT_LIGHT_OWNER="$session:$token" hyprsunset -t "$desired" </dev/null >/dev/null 2>&1 9>&- &
pid=$!
sleep 0.3
started=$(process_start "$pid") || { printf 'hyprsunset failed to start\n' >&2; exit 1; }
if ! has_environment "$pid" "QUICKSHELL_NIGHT_LIGHT_OWNER=$session:$token"; then
  printf 'Could not establish Night Light process ownership\n' >&2
  exit 1
fi
tmp=$(mktemp "$session_dir/.daemon.XXXXXX")
printf '%s %s %s %s\n' "$pid" "$started" "$desired" "$token" >"$tmp"
mv -f "$tmp" "$record"
