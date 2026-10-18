-- Run from desktop-settings.sh: all files/state are in its temporary HOME.
local configs, windows, layers = {}, {}, {}
local function rule_store(store)
  return function(spec)
    assert(not store[spec.name], "duplicate rule: " .. spec.name)
    function spec:set_enabled(enabled)
      assert(self.name == "opacity-toggle" or self.name:match("^effects%-blur%-"), "unrelated rule changed")
      self.enabled = enabled
    end
    store[spec.name] = spec
    return spec
  end
end
-- No monitor, dispatch, workspace, or binding APIs: appearance must not touch them.
hl = {
  config = function(spec) configs[#configs + 1] = spec end,
  window_rule = rule_store(windows),
  layer_rule = rule_store(layers),
  curve = function() end,
  animation = function(spec)
    if spec.leaf == "borderangle" then assert(not spec.enabled) end
  end,
  workspace_rule = function() end, -- initial smart-gap rules only
}
local look = require("config.look_and_feel")
require("config.windows_and_workspaces")
local effects = require("config.effects")
assert(not package.loaded["themes.wallust"], "generated palette must not be required/watched")
hl.workspace_rule = nil
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local window_count, layer_count = count(windows), count(layers)
local function preference(name, enabled)
  local path = os.getenv("XDG_STATE_HOME") .. "/hypr/effects/" .. name
  local file = assert(io.open(path, "w"))
  file:write(enabled and "enabled\n" or "disabled\n")
  file:close()
end
local function check(blur, opacity, low)
  effects.apply()
  assert(effects.blur == blur and effects.opacity == opacity and effects.low_effects == low)
  local config = configs[#configs]
  assert(config.decoration.blur.enabled == blur)
  assert(config.decoration.shadow.enabled == not low)
  assert(config.animations.enabled == not low)
  assert(windows["opacity-toggle"].enabled == not opacity)
  for _, namespace in ipairs({ "quickshell", "rofi", "notifications" }) do
    assert(layers["effects-blur-" .. namespace].enabled == blur)
  end
  assert(count(windows) == window_count and count(layers) == layer_count)
end
preference("blur", true); preference("opacity", true); preference("low-effects", false)
check(true, true, false)
preference("low-effects", true)
check(false, false, true)
preference("low-effects", false)
check(true, true, false)
preference("opacity", false)
check(true, false, false)
preference("opacity", true); preference("blur", false)
check(false, true, false)
preference("opacity", false)
check(false, false, false)
check(false, false, false)

local palette = os.getenv("HOME") .. "/.config/hypr/themes/wallust.lua"
local file = assert(io.open(palette, "w"))
file:write('return { color0="new0", color7="new7", color9="new9", color11="new11", color12="new12", color15="new15" }\n')
file:close()
look.apply_palette()
local colors = configs[#configs]
assert(colors.general.col.active_border.colors[1] == "new12")
assert(colors.group.col.border_active == "new15")
assert(colors.group.groupbar.col.active == "new0")
assert(not colors.decoration and not colors.master and not colors.dwindle)
assert(count(windows) == window_count and count(layers) == layer_count)
print("Runtime appearance updates preserve unrelated rules and reread preferences/palette")
