#!/bin/bash

# Launch Kitty and wait a moment for it to open and potentially grab focus
$USER_TERMINAL -e "ncspot" &
$USER_TERMINAL -e "cava" &
sleep 1
hyprctl dispatch movefocus r # 'd' for down
hyprctl dispatch togglesplit
# sleep 1 # Adjust sleep time as needed

# Explicitly focus Kitty (use a reliable selector)
# Option 1: by class (often best) - find class with 'hyprctl clients'
# hyprctl dispatch focuswindow class:cava # Or 'Alacritty', 'konsole', etc.
# Option 2: by title (can change)
# hyprctl dispatch focuswindow title:"user@host: ~" # Example title

# Move focus to the area below the currently focused window (Kitty)
# hyprctl dispatch movefocus d # 'd' for down
# hyprctl dispatch togglesplit

# Launch Firefox, it should open in the focused area below Kitty
# ncspot &
# sleep 1 # Give firefox time to open

# Now you can add commands to adjust heights if needed
# Example: Focus Kitty again and reduce its height, Firefox will expand
# hyprctl dispatch focuswindow class:cava
# hyprctl dispatch resizeactive 0 -100 # Decrease Kitty's height by 100px

# Example: Focus Firefox and increase its height
# hyprctl dispatch focuswindow class:firefox # Or 'firefoxdeveloperedition', etc.
# hyprctl dispatch resizeactive 0 100 # Increase Firefox's height by 100px
