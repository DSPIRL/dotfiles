#!/usr/bin/env bash
set -euo pipefail
exec "${HOME}/.config/hypr/scripts/desktop-settings.sh" blur "${1:-toggle}"
