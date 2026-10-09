-- Exercise the real keybinding callback without a compositor or window commands.
local root = (arg[0]:match("^(.*[/])") or "./") .. "../"
local toggle, window, border, calls
local function factory(name)
  return function(args) return { name = name, args = args } end
end
local dispatchers = setmetatable({}, { __index = function(_, name) return factory(name) end })
hl = {
  dsp = setmetatable({ window = dispatchers, workspace = dispatchers }, getmetatable(dispatchers)),
  on = function() end,
  bind = function(key, callback) if key == "SUPER + SHIFT + C" then toggle = callback end end,
  get_active_window = function() return window end,
  get_config = function(key) assert(key == "general.border_size"); return border end,
  dispatch = function(command)
    calls[#calls + 1] = command
    if command.name == "float" then window.floating = not window.floating end
  end,
}
package.loaded["config.defaults"] = setmetatable({ mainMod = "SUPER" }, { __index = function() return "/unused" end })
package.loaded["config.utils"] = { dispatch_all = function() return function() end end }
package.loaded["config.monitors"] = {}
dofile(root .. "dot_config/hypr/config/keybinds.lua")
assert(type(toggle) == "function")

for index, case in ipairs({
  { width = 1920, height = 1200, top = 0, bottom = 0, border = 2, floating = false },
  { width = 5120, height = 1440, top = 38, bottom = 0, border = 3, floating = false },
  { width = 1024, height = 640, top = 38, bottom = 12, border = 4, floating = true },
}) do
  border, calls = case.border, {}
  window = {
    address = tostring(index), floating = case.floating,
    at = { x = 90, y = 60 }, size = { x = 800, y = 500 },
    monitor = { width = case.width, height = case.height, reserved = { top = case.top, bottom = case.bottom } },
  }
  toggle()
  local resize = calls[#calls - 1]
  assert(resize.name == "resize" and resize.args.exact)
  assert(resize.args.x == math.floor(case.width / 2))
  assert(resize.args.y + 2 * border == case.height - case.top - case.bottom)
  assert(calls[#calls].name == "center" and window.floating)

  calls = {}
  toggle()
  assert(window.floating == case.floating)
  if case.floating then
    assert(calls[1].name == "resize" and calls[1].args.x == 800 and calls[1].args.y == 500)
    assert(calls[2].name == "move" and calls[2].args.x == 90 and calls[2].args.y == 60)
  else
    assert(#calls == 1 and calls[1].name == "float")
  end
end
window, calls = nil, {}
toggle()
assert(#calls == 0)
print("Centered-window border clearance and toggle restoration checks passed")
