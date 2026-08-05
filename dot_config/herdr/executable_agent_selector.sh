#!/usr/bin/env bash
set -euo pipefail

sel="$(herdr agent list \
  | jq -r '.result.agents[] | "\(.name // .pane_id)\t\(.workspace_name // .workspace // "")\t\(.state // "")"' \
  | column -t -s $'\t' \
  | fzf --prompt='agent> ')" || exit 0

[ -n "$sel" ] || exit 0

target="$(printf '%s' "$sel" | awk '{print $1}')"
herdr agent focus "$target"