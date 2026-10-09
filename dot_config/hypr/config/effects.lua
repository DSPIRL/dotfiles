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

local low_effects = preference("low-effects", require("config.performance-profile").enabled)
return {
  low_effects = low_effects,
  blur = preference("blur", not require("config.blur-toggle").enabled) and not low_effects,
  opacity = preference("opacity", not require("config.opacity-toggle").enabled) and not low_effects,
}
