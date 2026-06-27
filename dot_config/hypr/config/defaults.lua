local home = os.getenv("HOME") or "/home/athe"
local scripts = home .. "/.config/hypr/scripts"

return {
  mainMod = "SUPER",

  terminal = os.getenv("USER_TERMINAL") or os.getenv("ALT_TERMINAL") or "ghostty",
  editor = os.getenv("EDITOR") or "vi",
  fileManager = "nautilus",
  browser = "zen_browser",
  searchEngine = "https://kagi.com/search?q={}",
  notifications = "qs ipc call notifications toggle",
  controlPanel = "qs ipc call control toggle",
  barReload = scripts .. "/quickshell-reload.sh",
  barDoctor = scripts .. "/quickshell-healthcheck.sh",
  opacityToggle = scripts .. "/toggle-opacity.sh",
  performanceProfileToggle = scripts .. "/toggle-performance-profile.sh",
  themeToggle = scripts .. "/toggle-breeze-theme.sh",
  sessionTarget = scripts .. "/start-session-target.sh",

  screenshotWindow = "hyprshot -m window -o /tmp/hyprshot -f latest.png",
  screenshotRegion = "hyprshot -m region -o /tmp/hyprshot -f latest.png",
  editLastScreenshot = "spectacle --edit-existing /tmp/hyprshot/latest.png",

  music = scripts .. "/ncspot.sh",
  wallpaperGui = scripts .. "/waypaper.sh",
  telegram = "telegram",
  discord = "discord",

  idleHandler = "swayidle -w timeout 300 'swaylock -f -c 000000' before-sleep 'swaylock -f -c 000000'",
  locker = "hyprlock",

  appLauncher = scripts .. "/rofi-drun.sh",
  emojiPicker = scripts .. "/rofi-emoji-picker.sh",
  clipboard = scripts .. "/rofi-clipboard.sh",
  clipboardImages = scripts .. "/rofi-clipboard-images.sh",
  calculator = scripts .. "/rofi-calculator.sh",
  shell = scripts .. "/rofi-shell.sh",
  search = scripts .. "/rofi-search.sh",
}
