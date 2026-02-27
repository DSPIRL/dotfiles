#!/usr/bin/env bash
set -euo pipefail

pkill -x quickshell >/dev/null 2>&1 || true

for _ in 1 2 3 4 5; do
  if ! pgrep -x quickshell >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

quickshell >/dev/null 2>&1 &
