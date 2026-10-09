# Hyprland desktop controls

The desktop uses the existing Quickshell configuration, Wallust accents, and neutral surfaces. It does not require another shell framework or a custom backend daemon.

## Controls and shortcuts

- `Super+A`: open/close controls on the focused monitor.
- **Quick**: network settings (`nmtui`), Bluetooth settings (`blueman-manager`), night light, keep awake, audio devices/mute/volume, display brightness, and quiet notifications.
- **Desktop**: low-effects mode, blur, configured transparency, light/dark theme, wallpaper, bar visibility, and maintenance tools.
- `Super+Shift+B`: show/hide the bar. Controls remain accessible while it is hidden.
- `Super+Ctrl+R`: reload Hyprland.
- `Super+Shift+C`: toggle a centered, half-width floating window. Its height leaves room for both borders within the usable screen area; toggle again to restore its previous state.
- Active-window borders use the wallpaper-derived gradient without continuous rotation.
- `Super+Shift+L`: lock. Navigation, workspace movement, screenshots, and the exit shortcut are unchanged.
- Tab/Shift+Tab move focus; Space activates controls; Enter also activates buttons. Arrow keys adjust sliders. Escape closes controls or backs out of session actions.

The former blur, opacity, performance, theme, diagnostics, and monitor-reapply shortcuts are replaced by the menu. Their scripts remain available for custom shortcuts.

The footer and bar power button open the session menu. Suspend, logout, reboot, and shutdown require confirmation. Missing dependencies are reported or disable the relevant control. Quiet notifications retain history and allow critical alerts; quiet mode and keep-awake are temporary, shared across monitors, and reset when Quickshell reloads/exits.

## Effects and persistent preferences

```bash
~/.config/hypr/scripts/desktop-settings.sh status
~/.config/hypr/scripts/desktop-settings.sh blur disable
~/.config/hypr/scripts/desktop-settings.sh opacity enable
~/.config/hypr/scripts/desktop-settings.sh low-effects toggle
```

Individual features accept `status`, `enable`, `disable`, or `toggle`. The existing `toggle-blur.sh`, `toggle-opacity.sh`, and `toggle-performance-profile.sh` wrappers accept the same operations; no argument still toggles.

Runtime preferences live in `${XDG_STATE_HOME:-~/.local/state}/hypr/effects/`. The first invocation imports the old live Lua flags; managed Lua files subsequently supply defaults only. Applying chezmoi no longer resets these preferences. A failed compositor reload restores the previous preference.

Low-effects mode overrides blur, configured transparency, animations, and shadows without erasing the saved blur/transparency preferences. The menu shows effective state and disables overridden switches. Configured transparency refers to Hyprland opacity rules, not an application's own background alpha.

Theme state remains in `${XDG_STATE_HOME:-~/.local/state}/hypr/breeze-theme`. The existing theme script updates application themes and Rofi surfaces; Quickshell observes the same preference. `wallust-refresh` reapplies Rofi's selected light/dark surface after generating wallpaper colors and restarts an already-running Quickshell to load its new palette. Update both the Quickshell fallback palette and its Wallust template when changing shared style tokens.

## Idle locking and keep-awake

`hypridle` starts with Hyprland using `~/.config/hypr/hypridle.conf`:

- Lock after five idle minutes using `hyprlock`.
- Blank displays after five and a half idle minutes; restore them on activity.
- Request locking before sleep and delay sleep until the Wayland session is locked (`inhibit_sleep = 3`).

Keep-awake holds a systemd **idle-only** inhibitor. It suppresses automatic idle actions, including while the bar is hidden. It does not inhibit sleep, manual locking, or lock-before-sleep. The inhibitor releases when disabled or Quickshell exits. The control is unavailable if the idle handler is not running. The Suspend action also requires a running hypridle and installed hyprlock.

## CachyOS installation

Run the existing installer:

```bash
bash ~/.local/share/chezmoi/install_scripts/executable_hyprland_install.sh
```

The CachyOS main installer delegates to it when Hyprland setup is selected. It installs the desktop package list, runs the existing backlight/greetd/KWallet modules, imports existing live preferences before applying desktop-related dotfiles, enables NetworkManager and Bluetooth, and runs the health check. Quickshell and hypridle start on the next Hyprland login. It does not enable a second notification daemon; Quickshell handles notifications.

The package list includes `blueman`, `pavucontrol`, `networkmanager`, `hypridle`, `hyprlock`, `noto-fonts`, and `ttf-hack-nerd`. Existing machines missing these dependencies need the relevant packages installed; editing/applying the configuration alone does not install them.

## Recovery and verification

```bash
~/.config/hypr/scripts/quickshell-healthcheck.sh
~/.config/hypr/scripts/quickshell-reload.sh
quickshell log -p ~/.config/quickshell/default -t 80
hyprctl configerrors
systemd-inhibit --list
```

The health-check report is saved to `~/.cache/quickshell-healthcheck.log`. For direct control:

```bash
qs ipc call control toggle
qs ipc call control session
qs ipc call notifications quiet true
qs ipc call notifications isQuiet
qs ipc call control keepAwake false
qs ipc call control isKeepingAwake
```

Run `bash tests/desktop-settings.sh` for isolated migration, idempotence, override, rollback, concurrency, and Lua/CLI agreement checks. `lua tests/centered-window.lua` checks border clearance and toggle restoration without modifying live windows. Installer checks in `tests/hyprland-installer.sh` stub all installation/deployment commands; they do not install packages or modify services.

After applying QML edits, use `quickshell-reload.sh` rather than relying on hot reload. QML syntax checks are only a proxy. Verify the live panel with dark/light themes, blur disabled, expanded device lists, keyboard navigation, smaller/scaled displays, and a hidden bar. Test session actions manually only when it is safe to lock or leave the session.
