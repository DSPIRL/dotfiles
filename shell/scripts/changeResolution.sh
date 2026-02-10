#!/usr/bin/env bash

# set the display info
width=2560
height=1300
refresh_rate=60.00
display=Virtual-1
mode_name="${width}x${height}_${refresh_rate}"

# Get the modeline from running "cvt" and passing the width and height as params
originalModeline=$(cvt $width $height | grep Modeline)
# Remove the word "Modeline " from the beginning of the line
modeline=${originalModeline#Modeline }
# Cut and separate the blocks
mode_params=$(echo $modeline | cut -d ' ' -f2-)

# Create a new mode, add it, and set it as the output
xrandr --newmode "$mode_name" $mode_params
xrandr --addmode "$display" "$mode_name"

xrandr --output "$display" --mode "$mode_name"
