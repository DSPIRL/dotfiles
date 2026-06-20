#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi"
else
    rofi_theme="$HOME/.config/rofi/config-clipboard-images.rasi"
    rofi -modi clipimages:~/.local/scripts/cliphist-rofi-img -config "$rofi_theme" -show clipimages -show-icons
fi
