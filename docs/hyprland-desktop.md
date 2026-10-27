# Hyprland desktop controls

The desktop uses the existing Quickshell configuration, Wallust accents, and neutral surfaces. It does not require another shell framework or a custom backend daemon.

## Controls and shortcuts

- `Super+A`: open/close controls on the focused monitor.
- Controls open in a top-right, screen-constrained 640 × 740 logical-pixel frame. Category icons retain text labels; narrow screens scroll the category strip. Quick is initial, and the last category is remembered until the shell restarts.
- **Quick**: network settings (`nmtui`), Bluetooth settings (`blueman-manager`), Night light, Keep awake, Quiet notifications, output mute/volume, laptop brightness (or the first adjustable external display), and Audio/Display shortcuts. Network/Bluetooth buttons open existing tools; they are not radio toggles.
- **Music**: MPRIS artwork, title/artist/album, player selection, playback and capability-gated seeking. Missing players/artwork have fallbacks; only local file and HTTPS artwork URLs are loaded. Metadata is plain text. Position refreshes only while visible and playing, pausing during scrubbing. This is playback control, not a library manager; the Spotify bar remains unchanged.
- **Look & Feel**: shell glass, independent glass/control/window opacity, compositor-wide blur, light/dark theme, wallpaper, screen color picker and bar visibility.
- **Audio**: output/input devices, mute and volume. Only one device-selection submenu opens at once; Escape dismisses it before closing controls.
- **Display**: Night light, laptop/DDC brightness, monitor resolution and detection refresh.
- **System**: CPU/RAM/temperature (click for `btop`), software updates, diagnostics and maintenance. Low-effects mode, Lock and Session remain in the shared footer on every category.
- `Super+N`: open/close notification history. The bar has no notification or control-center button; these shortcuts remain available.
- `Super+Shift+B`: show/hide the bar with a 200 ms, 12 px slide-and-fade (up to hide, down to show; no bounce). Low-effects mode makes the toggle instant. Controls remain accessible while it is hidden.
- `Super+Ctrl+R`: reload Hyprland.
- `Super+Shift+C`: toggle a centered, half-width floating window. Its height leaves room for both borders within the usable screen area; toggle again to restore its previous state.
- Active-window borders use the wallpaper-derived gradient without continuous rotation.
- `Super+Shift+L`: lock. Navigation, workspace movement, screenshots, and the exit shortcut are unchanged.
- Tab/Shift+Tab move focus; Space/Enter activate controls. Left/Right switch categories while a category has focus; Home/End select the first/last. Drag sliders or use arrow keys to adjust them. The mouse wheel scrolls the page—even over a focused slider—and never changes slider values. Escape dismisses an audio device submenu or backs out of session confirmation/actions before closing controls. Closing resets detail menus and confirmations, not the selected category.

The former blur, opacity, performance, theme, diagnostics, and monitor-reapply shortcuts are replaced by the menu. Their scripts remain available for custom shortcuts.

The footer and bar power button open the session menu. Suspend, logout, reboot, and shutdown require confirmation. Missing dependencies are reported or disable the relevant control. Night light, Keep awake, and Quiet notifications save their selected state and restore it after shell restarts and logins. Quiet mode retains history and allows critical alerts; normal startup popups are suppressed until saved preferences are loaded. These are shared across monitors. This persists the notification preference, not notification history across process restarts.

## Typography (file-only)

Edit **`~/.config/quickshell/default/Typography.qml`** through chezmoi:

```bash
chezmoi edit --apply ~/.config/quickshell/default/Typography.qml
~/.config/hypr/scripts/quickshell-reload.sh
```

The managed source is `dot_config/quickshell/default/Typography.qml`. Its editable settings are grouped above the derived font roles:

- **Defaults**: `textFamily`, `iconFamily`, `normalWeight`, `emphasisWeight`, and icon weights.
- **Bar**: `barSize` changes every pill's text (default 14 logical pixels). Clock and workspace weights remain explicit; `barIconSize`/`barIconWeight` are independent. `barAudioIconSize` defaults to 20 for optical balance of Material volume glyphs with the other 14-pixel icons. Its fixed-width slot prevents state-dependent crowding; bar height and text sizing are unchanged.
- **Notifications**: title, body, metadata, and action sizes/weights. These apply to both popup and history-card content.
- **Notification center**: the panel title, empty state, header buttons, and decorative icon, independent of notification content.
- **Control center**: title, section headings, labels, emphasized buttons, hints, messages, metrics, and icons. `controlTileIconSize` controls dashboard/category and mute glyphs (default 20), with normal/emphasis weights; `controlIconSize` retains the small-icon font role. Neither changes bar icons. Audio and Quick mute targets are 40-pixel squares at the default typography, growing with text, and their adjacent headers match their height. Speaker/microphone glyphs use the same Material icon set.

Area families/weights inherit shared defaults until explicitly overridden. Use positive pixel sizes and named weights such as `Font.Normal`, `Font.Medium`, `Font.DemiBold`, and `Font.Bold`. Font families must be installed; unavailable faces/weights may fall back or be synthesized. Tray icons/application logos are images, not fonts.

Components bind complete font roles from one QML singleton; remaining state changes choose between those roles instead of adding local font overrides. Notification buttons explicitly select notification/center roles so control-center changes do not leak into them. Buttons/toggles and panel chrome grow with text metrics, but the bar's 36-pixel pills remain fixed: very large bar fonts can overflow, so check the live result.

Typography is trusted QML configuration, not a runtime preference database. It persists in the file and is not stored under `~/.local/state`. Wallpaper generation owns colors only and cannot reset these settings. There are no font controls in the UI. Apply/reload after editing, and check Quickshell logs for syntax or binding errors; no Hyprland reload is needed.

## Rofi appearance

The existing application, run, window, search, calculator, clipboard, emoji, and image-grid launchers share a Quickshell-like glass theme: a translucent gradient, 26-pixel outer corners, quiet card selections, and wallpaper accents. Hyprland supplies backdrop blur; there is no screenshot/refraction shader. Search-only modes keep the same padded input surface as the main launcher. All eight launcher configs share the same top-center anchor and 18% vertical offset in `rofi/themes/templates/rounded-template-wallust.rasi`; different window heights/widths do not move that anchor. Change placement there, not in individual mode configs.

The application launcher alone (`config-apps.rasi`) uses 42-pixel icons, name-only rows, separators, and six visible results (four on short displays). Generic names, keywords and desktop comments are searchable: `drun-match-fields` includes `name,generic,exec,categories,keywords,comment`, while `drun-display-format` shows only `{name}`. Other modes retain their own compact/grid layouts.

Edit `~/.config/rofi/appearance.rasi` through chezmoi for Rofi-only fonts and corner radii. The default text is `Noto Sans 14px` (explicit Pango pixels, not 14 points); emoji grids use a larger emoji font. Layout lives in `rofi/themes/templates/rounded-template-wallust.rasi`, with grid-specific overrides. Close and reopen Rofi after applying edits; neither Quickshell nor Hyprland needs a reload.

Rofi does not read `Typography.qml` or Quickshell's glass/control opacity percentages. Its material has independent defaults. Backdrop blur is already shared through the compositor. Low-effects changes regenerate an opaque Rofi palette for the next launch, without changing GTK/KDE themes; if regeneration fails, the preference rolls back.

`toggle-breeze-theme.sh refresh-shell` renders the current light/dark and low-effects state into `~/.config/rofi/wallust/colors-rofi.rasi`, preserving a validated opaque accent token. Wallpaper refresh calls the same renderer after Wallust. Generation is locked and atomic, so parallel refreshes cannot expose partial Rasi. Edit the source templates/renderer rather than this generated file; the renderer never edits `appearance.rasi`.

`bash tests/rofi-theme.sh` checks accent migration/preservation, light/dark materials, low-effects and rollback, concurrent generation, and every launcher config using Rofi's resolved-theme output when available. Native visual checks use synthetic text, emoji, and image entries—not clipboard contents—and cancel without selecting a launcher action.

## Effects and persistent preferences

```bash
~/.config/hypr/scripts/desktop-settings.sh status
~/.config/hypr/scripts/desktop-settings.sh blur disable
~/.config/hypr/scripts/desktop-settings.sh opacity enable
~/.config/hypr/scripts/desktop-settings.sh shell-glass enable
~/.config/hypr/scripts/desktop-settings.sh glass-opacity 60
~/.config/hypr/scripts/desktop-settings.sh control-opacity 85
~/.config/hypr/scripts/desktop-settings.sh window-opacity 90
~/.config/hypr/scripts/desktop-settings.sh blur-size 5
~/.config/hypr/scripts/desktop-settings.sh low-effects toggle
~/.config/hypr/scripts/desktop-settings.sh night-light enable
~/.config/hypr/scripts/desktop-settings.sh keep-awake enable
~/.config/hypr/scripts/desktop-settings.sh quiet-notifications enable
```

Boolean features accept `status`, `enable`, `disable`, or `toggle`. `glass-opacity`, `control-opacity`, and `window-opacity` accept `status` (the default when omitted) or an integer from `0` to `100`. `blur-size` accepts `status` or an integer from `1` to `20`. The existing `toggle-blur.sh`, `toggle-opacity.sh`, and `toggle-performance-profile.sh` wrappers accept the same operations; no argument still toggles.

Runtime preferences live in `${XDG_STATE_HOME:-~/.local/state}/hypr/effects/`. The first invocation imports the old live Lua flags; managed Lua files subsequently supply defaults only. Applying chezmoi no longer resets these preferences. Effect toggles apply only the relevant compositor settings and existing opacity/layer-blur rules through `hyprctl repl`; they do not reload the config, reapply monitors, or reset centered-workspace/window state. A failed update restores the previous preference and attempts to reapply it. Shell glass, glass/control opacity, Keep awake, and Quiet notifications are shell-only: changing them saves preferences for Quickshell to observe, without calling the compositor or changing window rules.

The bar keeps its layer surface mapped and animates only its contents, avoiding a second compositor transition or changes to notification/control-center animations. Hidden and transitioning contents accept no pointer input. Screen space is released after hiding and reserved again when showing; rapid toggles reverse from the current animation position.

Adjust `pillMargin` in `dot_config/quickshell/default/components/BarWindow.qml` to change the space around the bar pills. It defaults to 4 logical pixels on every side; 36-pixel pills therefore reserve a 44-pixel bar area. Input regions and clock placement follow the same setting. Hyprland's own window gaps still contribute to the distance below the bar and are unchanged.

The bar uses three floating glass sections: workspaces (plus Spotify on wide screens), a centered clock/date, and tray/essential status indicators. The clock hides when there is insufficient space; glass gaps pass pointer input through to the desktop. By default, all bar-pill text—workspaces, clock, media, and status percentages—uses Noto Sans at 14 logical pixels; Nerd Font glyphs are separate icon-only labels, so numbers do not inherit the icon font. The bar, control center, notification center, and notification popups share a clear light material and a smoke-tinted dark material, using Hyprland backdrop blur—not optical refraction or screen capture. Low-alpha fills, translucent cards, and fading highlights along the top and bottom edges suggest curved glass without a heavy white or dark wash. Shared `GlassSurface.qml` owns edge highlights and shadows so the material stays consistent. Glass styling does not change compositor-wide blur strength; the explicit Hyprland blur slider does.

Shell glass is enabled by default and independently controls transparency of the bar, control center, and notifications. Configured transparency enables the Hyprland window-opacity slider for normal application windows. Its uniform percentage overrides the existing per-app opacity rules; `100%` is opaque and fullscreen windows always remain opaque. Turning the feature off or enabling low-effects mode forces normal windows opaque too, without erasing the saved percentage. It does not affect shell glass or an application's own background-alpha setting. Backdrop blur controls frosting independently: with blur off, glass remains transparent but unfrosted.

**Super+A → Look & Feel** replaces the old Desktop/Appearance disclosure. The category itself keeps niche settings off Quick; Low-effects stays in the persistent footer. Settings remain grouped by target:

- **Shell surfaces**: Shell glass, Glass opacity, and Control opacity. These affect shell backgrounds and control-center fills, not application windows.
- **Application windows**: Configured transparency and Hyprland window opacity.
- **Backdrop blur**: the shared compositor blur switch and strength, affecting blur-enabled windows and shell surfaces independently of opacity.
- **Theme & wallpaper**: two flat rows, without an enclosing card. Theme choices show an accent pill/checkmark only for the selected option; Wallpaper is a separate hoverable action row. Keyboard-focus outlines remain visible, and narrow/larger-font layouts wrap the selector rather than nesting another card.

The four sliders remain independent:

- **Glass opacity** (`0–100%`, default `40%`): shared backgrounds of the bar, control center, notification center, and notification popups. The old `control-center-opacity` value is imported once unless a global glass value already exists.
- **Control opacity** (`0–100%`, default `100%`): only control-center buttons/cards, including selected/hovered/disabled fills. Text and icons do not fade. It remains independent of Glass opacity and Shell glass; notification controls are unaffected.
- **Hyprland window opacity** (`0–100%`, default `100%`): uniform compositor opacity of normal windows when Configured transparency is enabled. It deliberately supersedes per-app opacity rules so the slider has consistent results even for applications with `override` rules. Fullscreen windows stay opaque. Changing only `decoration.active_opacity` was rejected because those per-app overrides would bypass the slider.
- **Hyprland blur size** (`1–20`, default `3`): compositor-wide blur size when Backdrop blur is enabled. Blur passes are left unchanged; stronger blur costs more GPU time and affects only surfaces with blur enabled.

Shell fill previews update immediately. One serialized, latest-value queue throttles numeric writes/compositor updates at a 60 ms interval (waiting for any current command), so long drags continue to preview rather than waiting for release and trailing edits are not lost. Values persist across shell restarts; unrelated monitor/layout/window rules are not reapplied. Named opacity rules merge in place instead of accumulating one rule per edit.

Low-effects mode overrides blur, configured transparency, shell glass, animations, and shadows without erasing their saved preferences. The menu shows effective state and disables overridden switches. Turning off Shell glass makes glass backgrounds opaque; control opacity remains independent. Low-effects mode forces both glass backgrounds and control fills opaque. Shell animations also stop in low-effects mode.

System statistics refresh only while System is visible. Software updates use `checkupdates` on the first System visit and every 15 minutes while visible, with a manual Refresh button. System remains instantiated after first use so in-flight checks can finish and results are cached for 15 minutes across page switches/reopens; hidden timers pause. A failed check is unavailable, not zero updates. Updating opens the existing terminal with `paru -Syu` (or `sudo pacman -Syu` when `paru` is absent). The color picker closes controls before sampling, so it does not sample the panel itself.

Theme state remains in `${XDG_STATE_HOME:-~/.local/state}/hypr/breeze-theme`. The existing theme script updates application themes and Rofi surfaces; Quickshell observes the same preference. `wallust-refresh` applies Hyprland border/group colors directly, reapplies Rofi's selected light/dark surface after generating wallpaper colors, and restarts an already-running Quickshell to load its new palette. Hyprland deliberately loads its generated Lua palette with `dofile`, not `require`, to keep wallpaper updates out of its config watcher. Running `wallust run` directly updates the file but does not apply Hyprland colors until the next refresh or config reload. Update both the Quickshell fallback palette and its Wallust template when changing shared style tokens.

When first deploying these changes, load the new Lua modules at the next login or with one explicit config reload when it is safe to reset runtime layout state. Subsequent appearance toggles and wallpaper refreshes need no full reload. **Reload Hyprland**, `Super+Ctrl+R`, and edits to watched config modules still perform a full reload and can reset runtime layouts; **Reapply monitor configuration** also intentionally changes display geometry.

## Night light and saved session choices

`night-light`, `keep-awake`, and `quiet-notifications` use the same atomic, locked preference store as the appearance controls. New installs default them off; first use imports an already-running night-light daemon. Existing `hyprsunset.sh enable|disable|toggle` commands also save the choice. Its `status` operation reports the running daemon; `desktop-settings.sh night-light status` reports the saved choice. The status JSON exposes both `nightLight` (actual) and `nightLightWanted` (saved).

Quickshell applies the saved night-light choice once at startup, launching `hyprsunset -t 4000` only if needed. Runtime restoration and manual toggles share a separate lock, and the daemon inherits neither lock nor command stdio. This avoids duplicate daemons and settings commands hanging behind a long-lived child. Failed manual changes roll back the saved choice; failed startup restoration leaves the choice saved and reports an error so the next restart can retry.

## Idle locking and keep-awake

`hypridle` starts with Hyprland using `~/.config/hypr/hypridle.conf`:

- Lock after five idle minutes using `hyprlock`.
- Blank displays after five and a half idle minutes; restore them on activity.
- Request locking before sleep and delay sleep until the Wayland session is locked (`inhibit_sleep = 3`).

Keep-awake holds a systemd **idle-only** inhibitor. It suppresses automatic idle actions, including while the bar is hidden. It does not inhibit sleep, manual locking, or lock-before-sleep. The inhibitor releases when disabled or Quickshell exits; a new shell reacquires it when the saved choice is on. It can be acquired before hypridle starts, avoiding a login-order race. Keep awake suppresses automatic idle locking/display blanking until switched off, including after a reboot. A runtime inhibitor failure does not erase the saved choice: the control reports it unavailable and can be toggled off/on to retry. The Suspend action also requires a running hypridle and installed hyprlock.

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

Run `bash tests/desktop-settings.sh` for isolated migration, idempotence, override, rollback, concurrency, Lua/CLI agreement, runtime rule reuse, and colors-only wallpaper refresh checks. These tests use compositor doubles; they do not prove live window geometry preservation. `lua tests/centered-window.lua` checks border clearance and toggle restoration without modifying live windows. Installer checks in `tests/hyprland-installer.sh` stub all installation/deployment commands; they do not install packages or modify services.

Run `bash tests/control-center.sh` for the native category window with mocked actions, audio details, MPRIS selection/capabilities/disappearance, narrow layout, larger category text, lifecycle, and session confirmation. It requires an unlocked Wayland session and skips otherwise; no real media/device/session actions execute. Existing shell-only tests still work offscreen.

Run `bash tests/session-preferences.sh` for saved quiet/keep-awake choices, cold night-light restoration, rapid keep-awake toggles, lock-fd cleanup, failure retention, and idle-only inhibitor teardown. Night-light, compositor, and inhibitor commands are mocked in an isolated HOME; no real session or locking is changed.

Material regression tests use Qt 6: `QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Basic /usr/lib/qt6/bin/qmltestrunner -input tests/tst_shell-material.qml`. They exercise normal/selected/hovered/disabled control fills, glass/control independence, both themes, low-effects overrides, and shared typography (including area isolation, text/icon weights, larger controls, and missing-device fallbacks) without accessing the live desktop. These are component tests, not a substitute for inspecting the full panel.

After applying QML edits, use `quickshell-reload.sh` rather than relying on hot reload. QML syntax checks are only a proxy. Verify the live panel with dark/light themes, blur disabled, expanded device lists, keyboard navigation, smaller/scaled displays, and a hidden bar. Test session actions manually only when it is safe to lock or leave the session.
