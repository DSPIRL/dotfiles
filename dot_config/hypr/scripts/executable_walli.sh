#!/usr/bin/env bash

if pgrep -x "walli-gui" >/dev/null; then
    pkill -x "walli-gui"
else
    walli-gui
fi
