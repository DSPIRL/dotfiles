#!/usr/bin/env bash
set -euo pipefail

unset GTK_THEME
systemctl --user unset-environment GTK_THEME >/dev/null 2>&1 || true

systemctl --user import-environment \
  DISPLAY \
  WAYLAND_DISPLAY \
  GDK_BACKEND \
  KDE_SESSION_VERSION \
  QT_QPA_PLATFORM \
  QT_QPA_PLATFORMTHEME \
  QT_QUICK_CONTROLS_STYLE \
  QT_STYLE_OVERRIDE \
  XCURSOR_SIZE \
  XCURSOR_THEME \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_DESKTOP \
  XDG_SESSION_TYPE

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd \
    DISPLAY \
    WAYLAND_DISPLAY \
    GDK_BACKEND \
    KDE_SESSION_VERSION \
    QT_QPA_PLATFORM \
    QT_QPA_PLATFORMTHEME \
    QT_QUICK_CONTROLS_STYLE \
    QT_STYLE_OVERRIDE \
    XCURSOR_SIZE \
    XCURSOR_THEME \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_DESKTOP \
    XDG_SESSION_TYPE
fi

systemctl --user start hyprland-session.target
