local root = (arg[0]:match("^(.*[/])") or "./") .. "../"
package.path = root .. "dot_config/hypr/?.lua;" .. package.path
local rules, binds, open = {}, {}, nil
local function factory() return function() return function() end end end
local dsp = setmetatable({ window = setmetatable({}, {__index = factory}), workspace = setmetatable({}, {__index = factory}) }, {__index = factory})
hl = {
  dsp = dsp,
  window_rule = function(rule) rules[#rules + 1] = rule end,
  layer_rule = function() end,
  on = function(event, fn) if event == "window.open" then open = fn end end,
  bind = function(key, fn) binds[key] = fn end,
  dispatch = function() error("dropdown was centered") end,
}
package.loaded["config.effects"] = { apply = function() end }
package.loaded["config.defaults"] = setmetatable({mainMod = "SUPER"}, {__index = function() return "/unused" end})
package.loaded["config.monitors"] = {}
dofile(root .. "dot_config/hypr/config/windows_and_workspaces.lua")
dofile(root .. "dot_config/hypr/config/keybinds.lua")
assert(binds["SUPER + semicolon"])
local found = {}
for _, rule in ipairs(rules) do
  if rule.match.class == "^(dropdown-alacritty)$" then
    for _, key in ipairs({"float", "size", "move", "opacity", "workspace"}) do
      if rule[key] ~= nil then found[key] = rule[key] end
    end
  end
end
assert(found.float and found.size == "504 504")
assert(found.move == "(monitor_w*0.5-252) 53")
assert(found.workspace == "special:dropdown silent" and found.opacity)
open({mapped=true, workspace={}, floating=true, fullscreen=0, class="dropdown-alacritty"})
local animations = {}
hl.config = function() end
hl.curve = function() end
hl.animation = function(animation) animations[animation.leaf] = animation end
hl.workspace_rule = function() end
local old_dofile = dofile
dofile = function(path)
  if path:match("/themes/wallust.lua$") then return {} end
  return old_dofile(path)
end
old_dofile(root .. "dot_config/hypr/config/look_and_feel.lua")
assert(animations.specialWorkspaceIn.style == "slidevert top")
assert(animations.specialWorkspaceOut.style == "slidevert bottom")
print("Dropdown configuration checks passed")
