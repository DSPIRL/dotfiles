#!/usr/bin/env bash

set -u

step="${BRIGHTNESS_STEP:-5%}"
direction="${1:-}"

notify_user() {
    local percent="${1:-}"
    local message="${2:-}"

    if ! command -v notify-send >/dev/null 2>&1; then
        return 0
    fi

    if [[ -n "${percent}" ]]; then
        notify-send -h "int:value:${percent}" -h "string:x-canonical-private-synchronous:brightness_notif" -u low "Brightness" "${percent}%"
    elif [[ -n "${message}" ]]; then
        notify-send -h "string:x-canonical-private-synchronous:brightness_notif" -u normal "Brightness" "${message}"
    fi
}

brightnessctl_backlight() {
    brightnessctl --class=backlight "$@"
}

current_percent() {
    local details=""
    local percent=""

    details="$(brightnessctl_backlight --machine-readable 2>/dev/null || true)"
    IFS=, read -r _device _class _current _max percent <<<"${details}"

    printf '%s\n' "${percent%%%}"
}

if ! command -v brightnessctl >/dev/null 2>&1; then
    notify_user "" "brightnessctl is not installed."
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

percent="$(current_percent)"

if [[ -n "${percent}" ]]; then
    notify_user "${percent}" ""
fi
