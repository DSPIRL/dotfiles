#!/usr/bin/env bash
set -euo pipefail

state_file="${XDG_STATE_HOME:-${HOME}/.local/state}/hypr/breeze-theme"
cursor_size="${BREEZE_CURSOR_SIZE:-24}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Breeze theme" "$1"
  fi
}

current_mode() {
  local mode=""

  if [ -r "$state_file" ]; then
    IFS= read -r mode < "$state_file" || true
  fi

  case "$mode" in
    light|dark) printf '%s\n' "$mode" ;;
    *) printf 'dark\n' ;;
  esac
}

write_gtk_settings() {
  local gtk_theme="$1"
  local icon_theme="$2"
  local cursor_theme="$3"
  local prefer_dark="$4"

  mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"

  cat > "${HOME}/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=${prefer_dark}
gtk-button-images=true
gtk-cursor-blink=true
gtk-cursor-blink-time=1000
gtk-cursor-theme-name=${cursor_theme}
gtk-cursor-theme-size=${cursor_size}
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-font-name=Noto Sans,  10
gtk-icon-theme-name=${icon_theme}
gtk-menu-images=true
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=ocean
gtk-theme-name=${gtk_theme}
gtk-toolbar-style=3
gtk-xft-dpi=98304
EOF

  cat > "${HOME}/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=${prefer_dark}
gtk-cursor-blink=true
gtk-cursor-blink-time=1000
gtk-cursor-theme-name=${cursor_theme}
gtk-cursor-theme-size=${cursor_size}
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-font-name=Noto Sans,  10
gtk-icon-theme-name=${icon_theme}
gtk-theme-name=${gtk_theme}
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=ocean
gtk-xft-dpi=98304
EOF

  cat > "${HOME}/.config/gtkrc" <<EOF
gtk-theme-name="${gtk_theme}"
gtk-icon-theme-name="${icon_theme}"
gtk-cursor-theme-name="${cursor_theme}"
gtk-cursor-theme-size=${cursor_size}
EOF
}

hypr_env() {
  local key="$1"
  local value="$2"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"

  hyprctl eval "env = ${key},\"${value}\"" >/dev/null 2>&1 || \
    hyprctl keyword env "${key},${value}" >/dev/null 2>&1 || true
}

write_xsettingsd() {
  local gtk_theme="$1"
  local icon_theme="$2"
  local cursor_theme="$3"

  mkdir -p "${HOME}/.config/xsettingsd"

  cat > "${HOME}/.config/xsettingsd/xsettingsd.conf" <<EOF
Net/CursorBlinkTime 1000
Net/CursorBlink 1
Gdk/UnscaledDPI 98304
Gdk/WindowScalingFactor 1
Gtk/EnableAnimations 1
Gtk/DecorationLayout "icon:minimize,maximize,close"
Net/ThemeName "${gtk_theme}"
Gtk/PrimaryButtonWarpsSlider 1
Gtk/ToolbarStyle 3
Gtk/MenuImages 1
Gtk/ButtonImages 1
Gtk/CursorThemeSize ${cursor_size}
Gtk/CursorThemeName "${cursor_theme}"
Net/SoundThemeName "ocean"
Net/IconThemeName "${icon_theme}"
Gtk/FontName "Noto Sans,  10"
EOF

  if pgrep -x xsettingsd >/dev/null 2>&1; then
    pkill -HUP xsettingsd >/dev/null 2>&1 || true
  elif command -v xsettingsd >/dev/null 2>&1; then
    xsettingsd >/dev/null 2>&1 &
  fi
}

apply_kde_settings() {
  local look_and_feel="$1"
  local color_scheme="$2"
  local icon_theme="$3"
  local cursor_theme="$4"
  local qt_custom_palette="$5"

  if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
    plasma-apply-lookandfeel -a "$look_and_feel" >/dev/null 2>&1 || true
  elif command -v lookandfeeltool >/dev/null 2>&1; then
    lookandfeeltool -a "$look_and_feel" >/dev/null 2>&1 || true
  fi

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$color_scheme" >/dev/null 2>&1 || true
  fi

  if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
    plasma-apply-cursortheme "$cursor_theme" >/dev/null 2>&1 || true
  fi

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$color_scheme" >/dev/null 2>&1 || true
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icon_theme" >/dev/null 2>&1 || true
    kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$look_and_feel" >/dev/null 2>&1 || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$cursor_theme" >/dev/null 2>&1 || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$cursor_size" >/dev/null 2>&1 || true

    for qtct_conf in "${HOME}/.config/qt5ct/qt5ct.conf" "${HOME}/.config/qt6ct/qt6ct.conf"; do
      [ -f "$qtct_conf" ] || continue
      kwriteconfig6 --file "$qtct_conf" --group Appearance --key color_scheme_path "~/.config/qt6ct/style-colors.conf" >/dev/null 2>&1 || true
      kwriteconfig6 --file "$qtct_conf" --group Appearance --key custom_palette "$qt_custom_palette" >/dev/null 2>&1 || true
      kwriteconfig6 --file "$qtct_conf" --group Appearance --key icon_theme "$icon_theme" >/dev/null 2>&1 || true
      kwriteconfig6 --file "$qtct_conf" --group Appearance --key style Breeze >/dev/null 2>&1 || true
    done
  fi
}

apply_runtime_settings() {
  local cursor_theme="$1"

  export GDK_BACKEND="wayland,x11"
  unset GTK_THEME
  export KDE_SESSION_VERSION="6"
  export QT_QPA_PLATFORM="wayland;xcb"
  export QT_QPA_PLATFORMTHEME="kde"
  export QT_QUICK_CONTROLS_STYLE="org.kde.desktop"
  export QT_STYLE_OVERRIDE="Breeze"
  export XCURSOR_THEME="$cursor_theme"
  export XCURSOR_SIZE="$cursor_size"

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor "$cursor_theme" "$cursor_size" >/dev/null 2>&1 || true
    hypr_env GDK_BACKEND "$GDK_BACKEND"
    hypr_env KDE_SESSION_VERSION "$KDE_SESSION_VERSION"
    hypr_env QT_QPA_PLATFORM "$QT_QPA_PLATFORM"
    hypr_env QT_QPA_PLATFORMTHEME "$QT_QPA_PLATFORMTHEME"
    hypr_env QT_QUICK_CONTROLS_STYLE "$QT_QUICK_CONTROLS_STYLE"
    hypr_env QT_STYLE_OVERRIDE "$QT_STYLE_OVERRIDE"
    hypr_env XCURSOR_THEME "$XCURSOR_THEME"
    hypr_env XCURSOR_SIZE "$XCURSOR_SIZE"
    hypr_env HYPRCURSOR_SIZE "$XCURSOR_SIZE"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user unset-environment GTK_THEME >/dev/null 2>&1 || true
    systemctl --user import-environment \
      GDK_BACKEND \
      KDE_SESSION_VERSION \
      QT_QPA_PLATFORM \
      QT_QPA_PLATFORMTHEME \
      QT_QUICK_CONTROLS_STYLE \
      QT_STYLE_OVERRIDE \
      XCURSOR_THEME \
      XCURSOR_SIZE >/dev/null 2>&1 || true
  fi

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
      "GDK_BACKEND=${GDK_BACKEND}" \
      "KDE_SESSION_VERSION=${KDE_SESSION_VERSION}" \
      "QT_QPA_PLATFORM=${QT_QPA_PLATFORM}" \
      "QT_QPA_PLATFORMTHEME=${QT_QPA_PLATFORMTHEME}" \
      "QT_QUICK_CONTROLS_STYLE=${QT_QUICK_CONTROLS_STYLE}" \
      "QT_STYLE_OVERRIDE=${QT_STYLE_OVERRIDE}" \
      "XCURSOR_THEME=${XCURSOR_THEME}" \
      "XCURSOR_SIZE=${XCURSOR_SIZE}" >/dev/null 2>&1 || true
  fi
}

apply_gsettings() {
  local gtk_theme="$1"
  local icon_theme="$2"
  local cursor_theme="$3"
  local color_preference="$4"

  if ! command -v gsettings >/dev/null 2>&1; then
    return 0
  fi

  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface color-scheme "$color_preference" >/dev/null 2>&1 || true
}

apply_mode() {
  local mode="$1"
  local gtk_theme=""
  local gtk_icon_theme=""
  local kde_icon_theme=""
  local cursor_theme=""
  local prefer_dark=""
  local color_preference=""
  local look_and_feel=""
  local color_scheme=""
  local qt_custom_palette=""

  case "$mode" in
    dark)
      gtk_theme="Adwaita"
      gtk_icon_theme="Adwaita"
      kde_icon_theme="breeze-dark"
      cursor_theme="breeze_cursors"
      prefer_dark="true"
      color_preference="prefer-dark"
      look_and_feel="org.kde.breezedark.desktop"
      color_scheme="BreezeDark"
      qt_custom_palette="true"
      ;;
    light)
      gtk_theme="Adwaita"
      gtk_icon_theme="Adwaita"
      kde_icon_theme="breeze"
      cursor_theme="Breeze_Light"
      prefer_dark="false"
      color_preference="prefer-light"
      look_and_feel="org.kde.breeze.desktop"
      color_scheme="BreezeLight"
      qt_custom_palette="false"
      ;;
    *)
      printf 'Usage: %s [apply|toggle|dark|light|status]\n' "${0##*/}" >&2
      exit 2
      ;;
  esac

  mkdir -p "$(dirname "$state_file")"
  printf '%s\n' "$mode" > "$state_file"

  apply_kde_settings "$look_and_feel" "$color_scheme" "$kde_icon_theme" "$cursor_theme" "$qt_custom_palette"
  write_gtk_settings "$gtk_theme" "$gtk_icon_theme" "$cursor_theme" "$prefer_dark"
  write_xsettingsd "$gtk_theme" "$gtk_icon_theme" "$cursor_theme"
  apply_gsettings "$gtk_theme" "$gtk_icon_theme" "$cursor_theme" "$color_preference"
  apply_runtime_settings "$cursor_theme"

  # notify "Applied Breeze ${mode}"
}

case "${1:-toggle}" in
  apply)
    apply_mode "$(current_mode)"
    ;;
  toggle)
    case "$(current_mode)" in
      dark) apply_mode light ;;
      *) apply_mode dark ;;
    esac
    ;;
  dark|light)
    apply_mode "$1"
    ;;
  status)
    current_mode
    ;;
  *)
    printf 'Usage: %s [apply|toggle|dark|light|status]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
