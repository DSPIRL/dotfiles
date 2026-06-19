#!/usr/bin/env bash

if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi" && pkill -x "rofimoji"
else
    rofi_theme="$HOME/.config/rofi/config-emoji.rasi"
    rofimoji --max-recent 5 --hidden-descriptions --selector-args="-config $rofi_theme -kb-row-left Left -kb-row-right Right -kb-move-char-back Control+b -kb-move-char-forward Control+f" --action copy
fi
