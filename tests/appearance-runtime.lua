-- Run from desktop-settings.sh: all files/state are in its temporary HOME.
local configs, windows, layers = {}, {}, {}
local opacity_updates = 0
local function rule_store(store)
  return function(spec)
    if spec.name == "opacity-toggle" then opacity_updates = opacity_updates + 1 end
    -- Hyprland merges named rule declarations into the existing rule.
    if store[spec.name] then
      assert(spec.name == "opacity-toggle" or spec.name:match("^effects%-blur%-"), "unrelated rule redeclared")
      for key, value in pairs(spec) do store[spec.name][key] = value end
      return store[spec.name]
    end
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
  file:write(type(enabled) == "boolean" and (enabled and "enabled\n" or "disabled\n") or tostring(enabled) .. "\n")
  file:close()
end
local function check(blur, opacity, low)
  effects.apply()
  assert(effects.blur == blur and effects.opacity == opacity and effects.low_effects == low)
  local config = configs[#configs]
  assert(config.decoration.blur.enabled == blur)
  assert(config.decoration.blur.size == effects.blur_size)
  assert(config.decoration.blur.passes == nil, "slider must not change blur passes")
  assert(config.decoration.shadow.enabled == not low)
  assert(config.animations.enabled == not low)
  local alpha = opacity and effects.window_opacity / 100 or 1
  assert(windows["opacity-toggle"].enabled)
  assert(windows["opacity-toggle"].opacity == string.format("%.2f override %.2f override 1.0 override", alpha, alpha))
  for _, namespace in ipairs({ "quickshell", "rofi", "notifications" }) do
    assert(layers["effects-blur-" .. namespace].enabled == blur)
    assert(layers["effects-blur-" .. namespace].blur_popups == (namespace == "quickshell"))
  end
  local shadow = assert(layers["control-center-shadow"])
  assert(shadow.match.namespace == "^quickshell-control-shadow$")
  assert(shadow.order == 1, "0.56.2 paints descending order: shadow must precede order-0 glass")
  assert(shadow.no_anim == true, "Detached shadow fadeout snapshots must not bypass mapped layer order")
  assert(shadow.blur == false and shadow.blur_popups == false, "Shadow must stay unblurred at every preference state")
  assert(not layers["effects-blur-quickshell-control-shadow"], "Shadow must not join the blur preference namespace list")
  for _, surface in ipairs({ "bar", "notification", "toast", "tray" }) do
    local namespace = "quickshell-" .. surface .. "-shadow"
    local rule = assert(layers[namespace])
    assert(rule.match.namespace == "^" .. namespace .. "$")
    assert(rule.order == 1 and rule.no_anim == true)
    assert(rule.blur == false and rule.blur_popups == false)
    assert(not layers["effects-blur-" .. namespace])
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

-- Numeric changes update the existing named rule and honor saved overrides.
preference("window-opacity", 65); preference("blur-size", 11)
preference("opacity", true); preference("blur", true)
check(true, true, false)
assert(effects.window_opacity == 65 and effects.blur_size == 11)
local updates = opacity_updates
check(true, true, false)
assert(opacity_updates == updates, "unchanged opacity must not redeclare its rule")
preference("low-effects", true)
check(false, false, true)
assert(effects.window_opacity == 65 and effects.blur_size == 11)
preference("low-effects", false)
check(true, true, false)
preference("window-opacity", 0)
check(true, true, false)
preference("window-opacity", 100); preference("blur-size", 3)
preference("opacity", false); preference("blur", false)
check(false, false, false)

-- The upgrade path reloads this module only, not monitor/window/layout modules.
package.loaded["config.effects"] = nil
effects = require("config.effects")
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
