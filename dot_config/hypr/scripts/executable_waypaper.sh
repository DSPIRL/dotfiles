#!/usr/bin/env bash

if pgrep -x "waypaper" >/dev/null; then
    pkill -x "waypaper"
else
    waypaper
fi
