#!/usr/bin/env bash
set -euo pipefail

: "${XDG_RUNTIME_DIR:?}" "${HYPRLAND_INSTANCE_SIGNATURE:?}"
exec 9>"$XDG_RUNTIME_DIR/dropdown-terminal-$HYPRLAND_INSTANCE_SIGNATURE.lock"
# Drop keypresses while another invocation is starting or toggling.
flock -n 9 || exit 0

fail() { echo "dropdown-terminal: $*" >&2; exit 1; }
window_state() {
  local clients state
  clients=$(timeout 1s hyprctl -j clients) || fail "cannot query Hyprland clients (IPC failed or timed out)"
  state=$(jq -er '
    if type != "array" then error("expected clients array") else
      [.[] | select(.initialClass == "dropdown-alacritty")] |
      if length == 0 then "absent"
      elif length == 1 and .[0].mapped != true then "unmapped"
      elif length == 1 and .[0].workspace.name == "special:dropdown" then "ready"
      else "misplaced" end
    end' <<<"$clients") || fail "invalid Hyprland clients response"
  printf '%s' "$state"
}

state=$(window_state)
[[ $state != misplaced ]] || fail "mapped dropdown is not uniquely on special:dropdown; move or close it before retrying"
[[ $state != unmapped ]] || fail "dropdown exists but is not mapped; check or close it before retrying"
if [[ $state == absent ]]; then
  alacritty --class dropdown-alacritty 9>&- &
  pid=$!
  deadline=$((SECONDS + 5))
  while :; do
    state=$(window_state)
    [[ $state != misplaced ]] || fail "mapped dropdown is not uniquely on special:dropdown; move or close it before retrying"
    [[ $state != ready ]] || break
    kill -0 "$pid" 2>/dev/null || fail "Alacritty exited before mapping; check its configuration and executable"
    (( SECONDS < deadline )) || fail "Alacritty did not map within 5 seconds; check it before retrying"
    sleep 0.1
  done
fi
timeout 1s hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropdown")' >/dev/null || fail "cannot toggle special:dropdown (IPC failed or timed out)"
