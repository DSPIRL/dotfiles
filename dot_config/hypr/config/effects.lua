-- Managed Lua flags supply defaults; the menu/CLI writes only runtime preferences.
local home = os.getenv("HOME")
local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then state_home = home .. "/.local/state" end
local state = state_home .. "/hypr/effects/"

local function preference(name, fallback)
  local file = io.open(state .. name, "r")
  if not file then return fallback end
  local value = file:read("*l")
  file:close()
  if value == "enabled" then return true end
  if value == "disabled" then return false end
  return fallback
end

local function read_preferences()
  local low_effects = preference("low-effects", require("config.performance-profile").enabled)
  return {
    low_effects = low_effects,
    blur = preference("blur", not require("config.blur-toggle").enabled) and not low_effects,
    opacity = preference("opacity", not require("config.opacity-toggle").enabled) and not low_effects,
  }
end

local M = read_preferences()
local opacity_rule
local blur_rules = {}

-- Called after app rules at startup, and directly through hyprctl repl thereafter.
-- Keep rule handles so applying preferences never recreates layout/window rules.
function M.apply()
  local current = read_preferences()
  hl.config({
    decoration = { blur = { enabled = current.blur }, shadow = { enabled = not current.low_effects } },
    animations = { enabled = not current.low_effects },
  })

  if not opacity_rule then
    opacity_rule = hl.window_rule({
      name = "opacity-toggle",
      match = { class = [[.*]] },
      opacity = "1.0 override 1.0 override 1.0 override",
      enabled = not current.opacity,
    })
  else
    opacity_rule:set_enabled(not current.opacity)
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
end

return M
