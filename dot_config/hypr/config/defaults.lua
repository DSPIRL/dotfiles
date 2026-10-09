local home = os.getenv("HOME") or "/home/athe"
local scripts = home .. "/.config/hypr/scripts"

return {
  mainMod = "SUPER",

  terminal = os.getenv("USER_TERMINAL") or os.getenv("ALT_TERMINAL") or "ghostty" or "alacritty",
  editor = os.getenv("EDITOR") or "vi",
  fileManager = "nautilus",
  -- browser = "zen_browser",
  browser = "helium-browser",
  searchEngine = "https://kagi.com/search?q={}",
  notifications = "qs ipc call notifications toggle",
  controlPanel = "qs ipc call control toggle",
  barToggle = "qs ipc call bar toggle",
  barReload = scripts .. "/quickshell-reload.sh",
  brightness = scripts .. "/brightness.sh",
  themeToggle = scripts .. "/toggle-breeze-theme.sh",
  windowStackToggle = scripts .. "/toggle-window-stack.sh",
  sessionTarget = scripts .. "/start-session-target.sh",

  screenshotWindow = "hyprshot -m window -o /tmp/hyprshot -f latest.png",
  screenshotRegion = "hyprshot -m region -o /tmp/hyprshot -f latest.png",
  editLastScreenshot = "spectacle --edit-existing /tmp/hyprshot/latest.png",

  music = scripts .. "/ncspot.sh",
  wallpaperGui = scripts .. "/waypaper.sh",
  telegram = "telegram",
  discord = "discord",

  idleHandler = "hypridle",
  locker = "hyprlock",

  appLauncher = scripts .. "/rofi-drun.sh",
  windowSwitcher = scripts .. "/rofi-windows.sh",
  emojiPicker = scripts .. "/rofi-emoji-picker.sh",
  clipboard = scripts .. "/rofi-clipboard.sh",
  clipboardImages = scripts .. "/rofi-clipboard-images.sh",
  calculator = scripts .. "/rofi-calculator.sh",
  shell = scripts .. "/rofi-shell.sh",
  search = scripts .. "/rofi-search.sh",
}
