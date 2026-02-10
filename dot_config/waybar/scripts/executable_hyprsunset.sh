#!/usr/bin/env bash

if pgrep -x "hyprsunset" >/dev/null; then
    pkill --signal INT hyprsunset
else
    hyprsunset -t 4000
fi
