#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi"
else
    rofi_theme="$HOME/.config/rofi/config-apps.rasi"
    rofi -config "$rofi_theme" -show drun -show-icons
fi
