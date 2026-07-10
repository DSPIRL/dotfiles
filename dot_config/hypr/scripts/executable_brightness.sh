#!/usr/bin/env bash

set -u

step="${BRIGHTNESS_STEP:-5%}"
direction="${1:-}"

brightnessctl_backlight() {
    brightnessctl --class=backlight "$@"
}

if ! command -v brightnessctl >/dev/null 2>&1; then
    echo "brightnessctl is not installed." >&2
    exit 1
fi

case "${direction}" in
up)
    brightnessctl_backlight set "${step}+"
    ;;
down)
    brightnessctl_backlight set "${step}-"
    ;;
*)
    echo "Usage: ${0##*/} {up|down}" >&2
    exit 2
    ;;
esac
