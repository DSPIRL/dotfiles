local vars = require("config.defaults")
local utils = require("config.utils")
local monitors = require("config.monitors")

local mainMod = vars.mainMod

local function main(key)
  return mainMod .. " + " .. key
end

local function main_alt(key)
  return mainMod .. " + ALT + " .. key
end

local function main_shift(key)
  return mainMod .. " + SHIFT + " .. key
end

local function main_shift_alt(key)
  return mainMod .. " + SHIFT + ALT + " .. key
end

local function main_ctrl(key)
  return mainMod .. " + CTRL + " .. key
end

-- Toggle the focused window into the middle half of its monitor. On the
-- Odyssey this is a centered 2560x1440 area -- effectively one 1440p display.
local centered_windows = {}

local function toggle_center_half()
  local window = hl.get_active_window()
  if not window or not window.monitor then
    return
  end

  local id = window.address
  local original = centered_windows[id]

  if original then
    centered_windows[id] = nil
    if original.floating then
      if not window.floating then
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
      end
      hl.dispatch(hl.dsp.window.resize({ x = original.w, y = original.h, exact = true }))
      hl.dispatch(hl.dsp.window.move({ x = original.x, y = original.y, exact = true }))
    elseif window.floating then
      hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end
    return
  end

  centered_windows[id] = {
    floating = window.floating,
    x = window.at.x,
    y = window.at.y,
    w = window.size.x,
    h = window.size.y,
  }

  local monitor = window.monitor
  local reserved = monitor.reserved or {}
  local width = math.floor(monitor.width / 2)
  local height = math.floor(monitor.height - (reserved.top or 0) - (reserved.bottom or 0))

  if not window.floating then
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  end
  hl.dispatch(hl.dsp.window.resize({ x = width, y = height, exact = true }))
  hl.dispatch(hl.dsp.window.center())
end

-- Toggle the current workspace between dwindle and a centered master layout.
-- The focused tiled window becomes the 50%-wide master; the other tiled
-- windows are stacked on its left and right. Rules are kept so repeat toggles
-- do not accumulate duplicate workspace rules.
local centered_workspaces = {}

local function toggle_center_workspace()
  local workspace = hl.get_active_workspace()
  if not workspace then
    return
  end

  local state = centered_workspaces[workspace.id]
  if not state then
    centered_workspaces[workspace.id] = {
      enabled = true,
      rule = hl.workspace_rule({
        workspace = tostring(workspace.id),
        layout = "master",
      }),
    }
    return
  end

  state.enabled = not state.enabled
  state.rule:set_enabled(state.enabled)
end

-- ROFI
hl.bind(main("SPACE"), hl.dsp.exec_cmd(vars.appLauncher))
hl.bind(main_alt("SPACE"), hl.dsp.exec_cmd(vars.shell))
hl.bind(main_alt("B"), hl.dsp.exec_cmd(vars.search))
hl.bind(main("V"), hl.dsp.exec_cmd(vars.clipboard))
hl.bind(main_alt("V"), hl.dsp.exec_cmd(vars.clipboardImages))
hl.bind(main_alt("C"), hl.dsp.exec_cmd(vars.calculator))
hl.bind(main("PERIOD"), hl.dsp.exec_cmd(vars.emojiPicker))

-- System
hl.bind(main("E"), hl.dsp.exec_cmd(vars.fileManager))
hl.bind(main("B"), hl.dsp.exec_cmd(vars.browser))
hl.bind(main("N"), hl.dsp.exec_cmd(vars.notifications))
hl.bind(main("A"), hl.dsp.exec_cmd(vars.controlPanel))
hl.bind(main("M"), hl.dsp.exec_cmd(vars.music))
hl.bind(main("W"), hl.dsp.exec_cmd(vars.wallpaperGui))
hl.bind(main("RETURN"), hl.dsp.exec_cmd(vars.terminal))

-- Windows and such
hl.bind(main_alt("RETURN"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(main("F"), hl.dsp.window.float())
hl.bind(main("TAB"), hl.dsp.exec_cmd(vars.windowStackToggle))
hl.bind(main("C"), hl.dsp.window.center())
hl.bind(main("P"), hl.dsp.window.pseudo())
hl.bind(main("S"), hl.dsp.layout("togglesplit"))

-- System keybinds
hl.bind(main("Q"), hl.dsp.window.close())
hl.bind(main_shift("ESCAPE"), hl.dsp.exit())
hl.bind(main_shift("S"), hl.dsp.exec_cmd(vars.screenshotRegion))
hl.bind(main_shift_alt("S"), hl.dsp.exec_cmd(vars.screenshotWindow))
hl.bind(main_shift("E"), hl.dsp.exec_cmd(vars.editLastScreenshot))
hl.bind(main_shift("R"), hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(main_shift("B"), hl.dsp.exec_cmd(vars.barToggle))
hl.bind(main_shift("I"), hl.dsp.exec_cmd(vars.barDoctor))
hl.bind(main_shift("O"), hl.dsp.exec_cmd(vars.opacityToggle))
hl.bind(main_shift("P"), hl.dsp.exec_cmd(vars.performanceProfileToggle))
hl.bind(main_shift("T"), hl.dsp.exec_cmd(vars.themeToggle))
hl.bind(main_shift("L"), hl.dsp.exec_cmd(vars.locker))
hl.bind(main_shift("C"), toggle_center_half)
hl.bind(main_shift_alt("C"), toggle_center_workspace)
hl.bind(main_shift("M"), function()
  monitors.apply()
end)

-- Event-driven clamshell mode: no polling or background process.
-- The lid switch is "on" while closed and "off" while open.
hl.bind("switch:on:Lid Switch", function()
  monitors.set_lid_closed(true)
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
  monitors.set_lid_closed(false)
end, { locked = true })

local focus_directions = {
  h = "left",
  l = "right",
  k = "up",
  j = "down",
}

for key, direction in pairs(focus_directions) do
  hl.bind(main(key), utils.dispatch_all(
    hl.dsp.focus({ direction = direction }),
    hl.dsp.window.bring_to_top()
  ))
  hl.bind(main_alt(key), hl.dsp.window.move({ direction = direction }))
end

for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(main(key), hl.dsp.focus({ workspace = i }))
  hl.bind(main_alt(key), hl.dsp.window.move({ workspace = i }))
end

hl.bind(main_ctrl("h"), hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(main_ctrl("j"), hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(main_ctrl("k"), hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(main_ctrl("l"), hl.dsp.workspace.move({ monitor = "r" }))

hl.bind(main("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main("mouse_up"), hl.dsp.focus({ workspace = "e-1" }))

hl.bind(main("mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(main("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(vars.brightness .. " up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(vars.brightness .. " down"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
