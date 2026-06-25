local home = os.getenv("HOME") or "/home/athe"

local env = {
	XDG_CURRENT_DESKTOP = "Hyprland",
	XDG_DATA_DIRS = home .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share",
	XDG_SESSION_DESKTOP = "Hyprland",
	XDG_SESSION_TYPE = "wayland",

	GDK_BACKEND = "wayland,x11",
	GTK2_RC_FILES = "/etc/gtk-2.0/gtkrc:" .. home .. "/.config/gtkrc",
	GTK_RC_FILES = "/etc/gtk/gtkrc:" .. home .. "/.config/gtkrc",

	KDE_SESSION_VERSION = "6",
	QT_QPA_PLATFORM = "wayland;xcb",
	QT_QPA_PLATFORMTHEME = "kde",
	QT_QUICK_CONTROLS_STYLE = "org.kde.desktop",
	QT_STYLE_OVERRIDE = "Breeze",
    CLUTTER_BACKEND = "wayland",
    QT_AUTO_SCREEN_SCALE_FACTOR = "1",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    SDL_VIDEODRIVER = "wayland",

	HYPRCURSOR_SIZE = "24",
	XCURSOR_SIZE = "24",
	XCURSOR_THEME = "breeze_cursors",

	ALT_TERMINAL = "alacritty",
	BROWSER = "xdg-open",
	EDITOR = "nvim",
	HYPR_CONFIG_PATH = home .. "/.config/hypr",
	HYPR_SCRIPTS = home .. "/.config/hypr/scripts",
    HYPRLAND_CONFIG = home .. "/.config/hypr",
	TERMINAL = "ghostty",
	USER_TERMINAL = "ghostty",
	VISUAL = "nvim",
}

for key, value in pairs(env) do
	hl.env(key, value)
end
