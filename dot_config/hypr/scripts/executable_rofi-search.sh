#!/usr/bin/env bash

# Define the path to the config file
config_file=$HOME/.config/hypr/conf/programs.conf

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Process the config file in memory, removing the $ and fixing spaces
config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')

# Source the modified content directly from the variable
eval "$config_content"

# Check if $term is set correctly
if [[ -z "$searchEngine" ]]; then
    echo "Error: \$searchEngine is not set in the configuration file!"
    exit 1
fi

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
# msg='‼️ **note** ‼️ search via default web browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
else
    # Open Rofi and pass the selected query to xdg-open for Google search
    # echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg" | xargs -I{} xdg-open $searchEngine
    echo "" | rofi -dmenu -config "$rofi_theme" | xargs -I{} xdg-open $searchEngine
fi
