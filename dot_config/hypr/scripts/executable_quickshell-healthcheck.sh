#!/usr/bin/env bash
set -euo pipefail

declare -a missing_cmds=()
declare -a missing_files=()

check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        missing_cmds+=("$1")
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        missing_files+=("$1")
    fi
}

check_cmd quickshell
check_cmd nmcli
check_cmd pavucontrol
check_cmd blueman-manager
# check_cmd swaync-client
check_cmd wlogout
check_cmd hyprpicker
check_cmd hyprsunset
check_cmd checkupdates
check_cmd playerctl

check_file "$HOME/.config/quickshell/shell.qml"
check_file "$HOME/.config/quickshell/components/BarWindow.qml"
check_file "$HOME/.config/quickshell/default/wallust/Colors.qml"
# check_file "$HOME/.config/swaync/wallust/colors-swaync.css"
check_file "$HOME/.config/hypr/scripts/quickshell-reload.sh"
check_file "$HOME/.config/hypr/scripts/colorpicker.sh"
check_file "$HOME/.config/hypr/scripts/hyprsunset.sh"

if pgrep -x quickshell >/dev/null 2>&1; then
    quickshell_state="running"
else
    quickshell_state="not running"
fi

report_file="$HOME/.cache/quickshell-healthcheck.log"
mkdir -p "$(dirname "$report_file")"

{
    echo "Quickshell Healthcheck"
    echo "State: $quickshell_state"

    if [ "${#missing_cmds[@]}" -eq 0 ]; then
        echo "Commands: ok"
    else
        echo "Commands missing: ${missing_cmds[*]}"
    fi

    if [ "${#missing_files[@]}" -eq 0 ]; then
        echo "Files: ok"
    else
        echo "Files missing:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
    fi
} | tee "$report_file"

if [ "$quickshell_state" = "running" ] && [ "${#missing_cmds[@]}" -eq 0 ] && [ "${#missing_files[@]}" -eq 0 ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Quickshell Healthcheck" "Healthy. Report: $report_file"
    fi
    exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Quickshell Healthcheck" "Issues found. Report: $report_file"
fi

exit 1
