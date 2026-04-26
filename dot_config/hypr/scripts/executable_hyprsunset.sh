#!/usr/bin/env bash

if pgrep -x hyprsunset >/dev/null 2>&1; then
  pkill --signal INT hyprsunset
else
  hyprsunset -t 4000
fi
