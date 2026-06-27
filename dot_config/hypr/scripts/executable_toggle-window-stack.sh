#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-window-stack"
mkdir -p "$state_dir"

active_json="$(hyprctl activewindow -j 2>/dev/null || true)"
active_window_present=true
if [ -z "$active_json" ] || [ "$active_json" = "{}" ]; then
  active_json="{}"
  active_window_present=false
fi

active_workspace_json="$(hyprctl activeworkspace -j 2>/dev/null || true)"

workspace_id="$(jq -r '.workspace.id // empty' <<<"$active_json")"
if [ -z "$workspace_id" ]; then
  workspace_id="$(jq -r '.id // empty' <<<"$active_workspace_json")"
fi

if [ -z "$workspace_id" ]; then
  exit 0
fi

if ! [[ "$workspace_id" =~ ^[0-9]+$ ]]; then
  exit 0
fi

if [ "$active_window_present" = "true" ]; then
  active_floating="$(jq -r '.floating // false' <<<"$active_json")"
else
  active_floating=false
fi
clients_json="$(hyprctl clients -j)"
state_file="$state_dir/${HYPRLAND_INSTANCE_SIGNATURE:-default}-$workspace_id"
stack_workspace="special:window-stack-$workspace_id"

floating_addresses="$(jq -r --argjson ws "$workspace_id" '.[] | select(.workspace.id == $ws and .floating == true and .pinned == false) | .address' <<<"$clients_json")"
target_floating="$(jq -r --argjson ws "$workspace_id" '[.[] | select(.workspace.id == $ws and .floating == true and .pinned == false)] | sort_by(.focusHistoryID) | .[0].address // empty' <<<"$clients_json")"
next_floating="$(jq -r --argjson ws "$workspace_id" '[.[] | select(.workspace.id == $ws and .floating == true and .pinned == false)] | sort_by(.focusHistoryID) | .[1].address // empty' <<<"$clients_json")"
target_tiled="$(jq -r --argjson ws "$workspace_id" '[.[] | select(.workspace.id == $ws and .floating == false)] | sort_by(.focusHistoryID) | .[0].address // empty' <<<"$clients_json")"
next_tiled="$(jq -r --argjson ws "$workspace_id" '[.[] | select(.workspace.id == $ws and .floating == false)] | sort_by(.focusHistoryID) | .[1].address // empty' <<<"$clients_json")"

focus_window() {
  local address="$1"

  [ -n "$address" ] || return 1
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
  hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = "top" })' >/dev/null
}

window_exists() {
  local address="$1"

  jq -e --arg address "$address" '.[] | select(.address == $address)' <<<"$clients_json" >/dev/null
}

stash_floating() {
  [ -n "$floating_addresses" ] || return 1

  printf '%s\n' "$floating_addresses" >"$state_file"
  while IFS= read -r address; do
    [ -n "$address" ] || continue
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$stack_workspace\", follow = false, window = \"address:$address\" })" >/dev/null
  done <<<"$floating_addresses"
}

restore_floating() {
  [ -s "$state_file" ] || return 1

  local first_address=""
  while IFS= read -r address; do
    [ -n "$address" ] || continue
    window_exists "$address" || continue
    hyprctl dispatch "hl.dsp.window.move({ workspace = $workspace_id, follow = false, window = \"address:$address\" })" >/dev/null
    if [ -z "$first_address" ]; then
      first_address="$address"
    fi
  done <"$state_file"

  rm -f "$state_file"
  [ -n "$first_address" ] || return 1
  focus_window "$first_address"
}

if [ -z "$target_tiled" ] && [ -s "$state_file" ]; then
  restore_floating || true
  exit 0
fi

if [ "$active_floating" = "true" ]; then
  if [ -n "$target_tiled" ]; then
    stash_floating
    focus_window "$target_tiled"
  elif [ -n "$next_floating" ]; then
    focus_window "$next_floating"
  fi
else
  if restore_floating; then
    exit 0
  elif [ -n "$target_floating" ]; then
    focus_window "$target_floating"
  elif [ -n "$next_tiled" ]; then
    focus_window "$next_tiled"
  elif [ -n "$target_tiled" ]; then
    focus_window "$target_tiled"
  fi
fi
