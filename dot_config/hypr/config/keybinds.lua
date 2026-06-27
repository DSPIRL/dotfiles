local vars = require("config.defaults")
local utils = require("config.utils")

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
hl.bind(main("TAB"), hl.dsp.exec_cmd([[if hyprctl activewindow -j | jq -e ".floating" >/dev/null; then hyprctl dispatch 'hl.dsp.window.cycle_next({ floating = true })'; else hyprctl dispatch 'hl.dsp.window.cycle_next({ tiled = true })'; fi]]))
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
hl.bind(main_shift("B"), hl.dsp.exec_cmd(vars.barReload))
hl.bind(main_shift("I"), hl.dsp.exec_cmd(vars.barDoctor))
hl.bind(main_shift("O"), hl.dsp.exec_cmd(vars.opacityToggle))
hl.bind(main_shift("P"), hl.dsp.exec_cmd(vars.performanceProfileToggle))
hl.bind(main_shift("T"), hl.dsp.exec_cmd(vars.themeToggle))
hl.bind(main_shift("L"), hl.dsp.exec_cmd(vars.locker))

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
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
