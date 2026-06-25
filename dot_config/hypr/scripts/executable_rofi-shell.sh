#!/usr/bin/env bash

export GDK_BACKEND="wayland,x11"
unset GTK_THEME
export KDE_SESSION_VERSION="6"
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME="kde"
export QT_QUICK_CONTROLS_STYLE="org.kde.desktop"
export QT_STYLE_OVERRIDE="Breeze"

if pgrep -x "rofi" >/dev/null; then
    pkill -x "rofi"
else
    rofi_theme="$HOME/.config/rofi/config-run.rasi"
    rofi -config "$rofi_theme" -show run -show-icons
fi
