#!/usr/bin/env bash

if pgrep -x "smile" >/dev/null; then
    pkill -x "smile"
else
    smile
fi
