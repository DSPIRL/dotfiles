-- Managed Lua flags supply defaults; the menu/CLI writes only runtime preferences.
local home = os.getenv("HOME")
local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then state_home = home .. "/.local/state" end
local state = state_home .. "/hypr/effects/"

local function read_value(name)
  local file = io.open(state .. name, "r")
  if not file then return nil end
  local value = file:read("*l")
  file:close()
  return value
end

local function preference(name, fallback)
  local value = read_value(name)
  if value == "enabled" then return true end
  if value == "disabled" then return false end
  return fallback
end

local function number_preference(name, fallback, minimum, maximum)
  local value = read_value(name)
  local number = tonumber(value)
  if number and value:match("^%d+$") and tostring(number) == value and number >= minimum and number <= maximum then return number end
  return fallback
end

local function read_preferences()
  local low_effects = preference("low-effects", require("config.performance-profile").enabled)
  return {
    low_effects = low_effects,
    blur = preference("blur", not require("config.blur-toggle").enabled) and not low_effects,
    opacity = preference("opacity", not require("config.opacity-toggle").enabled) and not low_effects,
    window_opacity = number_preference("window-opacity", 100, 0, 100),
    blur_size = number_preference("blur-size", 3, 1, 20),
  }
end

local M = read_preferences()
local opacity_value
local blur_rules = {}

-- Called after app rules at startup, and directly through hyprctl repl thereafter.
-- Keep rule handles so applying preferences never recreates layout/window rules.
function M.apply()
  local current = read_preferences()
  hl.config({
    decoration = { blur = { enabled = current.blur, size = current.blur_size }, shadow = { enabled = not current.low_effects } },
    animations = { enabled = not current.low_effects },
  })

  local alpha = current.opacity and current.window_opacity / 100 or 1
  local value = string.format("%.2f override %.2f override 1.0 override", alpha, alpha)
  if opacity_value ~= value then
    -- Named rules merge on redeclaration: update this rule in place, never append
    -- one rule per slider movement. Fullscreen windows remain opaque.
    hl.window_rule({
      name = "opacity-toggle",
      match = { class = [[.*]] },
      opacity = value,
      enabled = true,
    })
    opacity_value = value
  end

  for _, namespace in ipairs({ "quickshell", "rofi", "notifications" }) do
    if not blur_rules[namespace] then
      blur_rules[namespace] = hl.layer_rule({
        name = "effects-blur-" .. namespace,
        match = { namespace = namespace },
        blur = true,
        enabled = current.blur,
      })
    else
      blur_rules[namespace]:set_enabled(current.blur)
    end
  end
  M.low_effects, M.blur, M.opacity = current.low_effects, current.blur, current.opacity
  M.window_opacity, M.blur_size = current.window_opacity, current.blur_size
end

return M
