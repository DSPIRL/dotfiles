#!/usr/bin/env bash

if pgrep -x "wofi" >/dev/null; then
    pkill -x "wofi"
else
    cliphist list | wofi --allow-images --allow-markup --dmenu | cliphist decode | wl-copy
fi
