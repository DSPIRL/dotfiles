#!/usr/bin/env bash
set -euo pipefail
exec "${HOME}/.config/hypr/scripts/desktop-settings.sh" low-effects "${1:-toggle}"
