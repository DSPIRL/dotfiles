#!/usr/bin/env bash


if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi"
else
    rofi_theme="$HOME/.config/rofi/config-run.rasi"
    rofi -config $rofi_theme -show run -show-icons
fi
fi
