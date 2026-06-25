local utils = require("config.utils")
local opacity_toggle = require("config.opacity-toggle")

local wr = utils.window_rule
local lr = utils.layer_rule

-- CachyOS
wr("float on", { class = [[^(CachyOSHello|org.[Cc]achyos.[Hh]ello)$]] })
wr("float on", { class = [[^(zenity)$]] })

-- Ignore maximize requests from apps.
wr("suppress_event maximize", { class = [[.*]] }, "suppress-maximize-events")

-- Fix some dragging issues with XWayland.
wr("no_initial_focus on", { class = [[^$]], title = [[^$]], xwayland = true, float = true, fullscreen = false, pin = false }, "fix-xwayland-drags")

-- Browser tags
wr("tag +browser", { class = [[^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$]] })
wr("tag +browser", { class = [[^([Zz]en|[Zz]en-[Bb]rowser|app.zen_browser.zen)$]] })
wr("tag +browser", { class = [[^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$]] })
wr("tag +browser", { class = [[^(chrome-.+-Default)$]] })
wr("tag +browser", { class = [[^([Cc]hromium)$]] })
wr("tag +browser", { class = [[^([Vv]ivaldi|com.vivaldi.Vivaldi)$]] })
wr("tag +browser", { class = [[^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$]] })
wr("tag +browser", { class = [[^([Bb]rave-browser(-beta|-dev|-unstable)?)$]] })
wr("tag +browser", { class = [[^([Tt]horium-browser|[Cc]achy-browser)$]] })
wr("tag +browser", { class = [[^(zen-alpha|zen)$]] })

-- Terminal tags
wr("tag +terminal", { class = [[^([Aa]lacritty|kitty|kitty-dropterm|[Ww]ezterm|[Ww]ezterm-gui|org.wezfurlong.wezterm|[Gg]hostty|com.mitchellh.ghostty)$]] })

-- App tags
wr("tag +dictionary", { class = [[^(gnome-dictionary|org.gnome.[Dd]ictionary)$]] })
wr("tag +emoji", { class = [[^(smile|it.mijorus.smile|gnome-characters|org.gnome.Characters)$]] })
wr("tag +projects", { class = [[^(codium|codium-url-handler|VSCodium)$]] })
wr("tag +projects", { class = [[^(VSCode|code-url-handler)$]] })
wr("tag +projects", { class = [[^(jetbrains-.+|rustrover.+|webstorm.+|clion.+|pycharm.+|rider.+)$]] })
wr("tag +editors", { class = [[^(nvim)]] })
wr("tag +screenshare", { class = [[^(com.obsproject.Studio)$]] })
wr("tag +im", { class = [[^([Dd]iscord|[Ww]ebCord|[Vv]esktop|com.discordapp.Discord)$|.*[Dd]iscord$]] })
wr("tag +im", { class = [[^([Ff]erdium)$]] })
wr("tag +im", { class = [[^([Ww]hatsapp-for-linux)$]] })
wr("tag +im", { class = [[^(ZapZap|com.rtosta.zapzap)$]] })
wr("tag +im", { class = [[^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop|[Tt]elegram)$]] })
wr("tag +im", { class = [[^(teams-for-linux)$]] })
wr("tag +games", { class = [[^(gamescope)$]] })
wr("tag +games", { class = [[^(steam_app_\d+)$]] })
wr("tag +gamestore", { class = [[^([Ss]team)$]] })
wr("tag +gamestore", { title = [[^([Ll]utris)$]] })
wr("tag +gamestore", { class = [[^(com.heroicgameslauncher.hgl)$]] })
wr("tag +file-manager", { class = [[^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|[Nn]autilus|[Dd]olphin)$]] })
wr("tag +file-manager", { class = [[^(app.drey.Warp)$]] })
wr("tag +wallpaper", { class = [[^([Ww]aytrogen)$]] })
wr("tag +wallpaper", { class = [[^([Ww]aypaper)$]] })
wr("tag +multimedia", { class = [[^([Aa]udacious)$]] })
wr("tag +multimedia_video", { class = [[^([Mm]pv|vlc)$]] })
wr("tag +vpns", { class = [[^(protonvpn-app)$]] })
wr("tag +keychains", { class = [[^([Kk]ee[Pp]ass[Xx][Cc]|org.keepassxc.KeePassXC)$]] })
wr("tag +emacs", { class = [[^([Ee]macs)$]] })

-- Settings tags
wr("tag +settings", { class = [[^([Gg]ddccontrol)$]] })
wr("tag +settings", { title = [[^(ROG Control)$]] })
wr("tag +settings", { class = [[^(wihotspot(-gui)?)$]] })
wr("tag +settings", { class = [[^([Bb]aobab|org.gnome.[Bb]aobab)$]] })
wr("tag +settings", { class = [[^(gnome-disks|wihotspot(-gui)?)$]] })
wr("tag +settings", { title = [[(Kvantum Manager)]] })
wr("tag +settings", { class = [[^(file-roller|org.gnome.FileRoller)$]] })
wr("tag +settings", { class = [[^(nm-applet|nm-connection-editor|blueman-manager)$]] })
wr("tag +settings", { class = [[^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$]] })
wr("tag +settings", { class = [[^(qt5ct|qt6ct|[Yy]ad)$]] })
wr("tag +settings", { class = [[(xdg-desktop-portal-gtk)]] })
wr("tag +settings", { class = [[^(org.kde.polkit-kde-authentication-agent-1|polkit-gnome-authentication-agent-1|hyprpolkitagent|org.org.polkit-kde-authentication-agent-1)(.*)$]] })
wr("tag +settings", { class = [[^([Rr]ofi)$]] })

-- Viewer tags
wr("tag +viewer", { class = [[^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$]] })
wr("tag +viewer", { class = [[^(evince)$]] })
wr("tag +viewer", { class = [[^(eog|org.gnome.Loupe)$]] })

-- Special override rules
wr("no_blur on", { tag = "multimedia_video" })
wr("opacity 1.0 override", { tag = "multimedia_video" })

-- Position
wr("center on", { class = [[([Tt]hunar)]], title = [[negative:(.*[Tt]hunar.*)]] })
wr("center on", { title = [[^(ROG Control)$]] })
wr("center on", { title = [[^(Keybindings)$]] })
wr("center on", { class = [[^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$]] })
wr("center on", { class = [[^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$]] })
wr("center on", { class = [[^([Ff]erdium)$]] })
wr("move (monitor_w*0.72) (monitor_h*0.07)", { title = [[^(Picture-in-Picture)$]] })
wr("idle_inhibit fullscreen", { fullscreen = true })

-- Workspace routing
wr("workspace 1", { tag = "im" })
wr("workspace 5", { tag = "browser" })
wr("workspace 10", { tag = "games" })

-- Tag rules
wr("float on", { tag = "terminal" })
wr("size (monitor_w*0.8) (monitor_h*0.8)", { tag = "terminal" })
wr("opacity 0.9 override 0.8 override 1.0 override", { tag = "terminal" })
wr("opacity 0.9 override 0.8 override", { tag = "emacs" })

wr("float on", { tag = "im" })
wr("size (monitor_w*0.6) (monitor_h*0.6)", { tag = "im" })
wr("opacity 0.9 override 0.8 override", { tag = "im" })

wr("float on", { tag = "vpns" })
wr("size (monitor_w*0.1) (monitor_h*0.1)", { tag = "vpns" })
wr("center on", { tag = "vpns" })

wr("float on", { tag = "keychains" })
wr("size (monitor_w*0.5) (monitor_h*0.5)", { tag = "keychains" })
wr("center on", { tag = "keychains" })

wr("float on", { tag = "wallpaper" })
wr("size (monitor_w*0.7) (monitor_h*0.8)", { tag = "wallpaper" })
wr("opacity 0.9 override 0.8 override", { tag = "wallpaper" })

wr("float on", { tag = "dictionary" })
wr("size (monitor_w*0.1) (monitor_h*0.1)", { tag = "dictionary" })
wr("center on", { tag = "dictionary" })

wr("float on", { tag = "emoji" })
wr("size (monitor_w*0.1) (monitor_h*0.1)", { tag = "emoji" })
wr("center on", { tag = "emoji" })

wr("float on", { tag = "settings" })
wr("size (monitor_w*0.7) (monitor_h*0.7)", { tag = "settings" })
wr("opacity 0.9 override 0.8 override", { tag = "settings" })

wr("float on", { tag = "file-manager" })
wr("size (monitor_w*0.7) (monitor_h*0.7)", { tag = "file-manager" })
wr("opacity 0.9 override 0.8 override", { tag = "file-manager" })

wr("opacity 0.95 override 0.8 override", { tag = "browser" })

-- Floating rules
wr("float on", { tag = "viewer" })
wr("float on", { class = [[([Zz]oom|onedriver|onedriver-launcher)$]] })
wr("float on", { class = [[(org.gnome.Calculator)]], title = [[(Calculator)]] })
wr("float on", { class = [[^(mpv|com.github.rafostar.Clapper)$]] })
wr("float on", { class = [[^([Qq]alculate-gtk)$]] })
wr("float on", { class = [[^([Ff]erdium)$]] })
wr("float on", { title = [[^(Picture-in-Picture)$]] })

-- Float popups and dialogs
wr("float on", { title = [[^(Authentication Required)$]] })
wr("center on", { title = [[^(Authentication Required)$]] })
wr("float on", { class = [[(codium|codium-url-handler|VSCodium)]], title = [[negative:(.*codium.*|.*VSCodium.*)]] })
wr("float on", { class = [[^(com.heroicgameslauncher.hgl)$]], title = [[negative:(Heroic Games Launcher)]] })
wr("float on", { class = [[^([Ss]team)$]], title = [[negative:^([Ss]team)$]] })
wr("float on", { class = [[([Tt]hunar)]], title = [[negative:(.*[Tt]hunar.*)]] })

wr("float on", { title = [[^(Add Folder to Workspace)$]] })
wr("size (monitor_w*0.7) (monitor_h*0.6)", { title = [[^(Add Folder to Workspace)$]] })
wr("center on", { title = [[^(Add Folder to Workspace)$]] })

wr("float on", { title = [[^(Save As)$]] })
wr("size (monitor_w*0.7) (monitor_h*0.6)", { title = [[^(Save As)$]] })
wr("center on", { title = [[^(Save As)$]] })
wr("float on", { class = [[^()$]], title = [[^(Save File)$]] })
wr("float on", { class = [[^()$]], title = [[^(Open File)$]] })

wr("float on", { initial_title = [[(Open Files)]] })
wr("size (monitor_w*0.7) (monitor_h*0.6)", { initial_title = [[(Open Files)]] })

wr("float on", { title = [[^(SDDM Background)$]] })
wr("center on", { title = [[^(SDDM Background)$]] })
wr("size (monitor_w*0.16) (monitor_h*0.12)", { title = [[^(SDDM Background)$]] })

-- Opacity
wr("opacity 1.0 override 0.95 override 1.0 override", { tag = "projects" })
wr("opacity 0.94 override 0.86 override", { tag = "multimedia" })
wr("opacity 0.82 override 0.75 override", { tag = "viewer" })
wr("opacity 0.8 override 0.7 override", { class = [[^(gedit|org.gnome.TextEditor|mousepad)$]] })
wr("opacity 0.9 override 0.8 override", { class = [[^(deluge)$]] })
wr("opacity 0.9 override 0.8 override", { class = [[^(im.riot.Riot)$]] })
wr("opacity 0.9 override 0.8 override", { class = [[^(seahorse)$]] })
wr("opacity 0.95 override 0.75 override", { title = [[^(Picture-in-Picture)$]] })

if opacity_toggle.enabled then
  wr("opacity 1.0 override 1.0 override 1.0 override", { class = [[.*]] }, "opacity-toggle")
end

-- Size
wr("size (monitor_w*0.6) (monitor_h*0.7)", { class = [[^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$]] })
wr("size (monitor_w*0.6) (monitor_h*0.7)", { class = [[^([Ff]erdium)$]] })

-- Pinning and extras
wr("pin on", { title = [[^(Picture-in-Picture)$]] })
wr("keep_aspect_ratio on", { title = [[^(Picture-in-Picture)$]] })

-- Blur and fullscreen
wr("no_blur on", { tag = "games" })
wr("fullscreen on", { tag = "games" })

-- Layer rules
lr("blur on", { namespace = "quickshell" })
lr("ignore_alpha 0.1", { namespace = "quickshell" })
lr("blur on", { namespace = "rofi" })
lr("ignore_alpha 0", { namespace = "rofi" })
lr("blur on", { namespace = "notifications" })
lr("ignore_alpha 0", { namespace = "notifications" })
