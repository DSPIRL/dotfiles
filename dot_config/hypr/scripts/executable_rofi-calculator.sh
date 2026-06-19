#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi"
else
    rofi_theme="$HOME/.config/rofi/config-calc.rasi"
    rofi -show calc -modi calc -no-show-match -no-sort -config "$rofi_theme" -calc-command "echo -n '{result}' | wl-copy"
fi
