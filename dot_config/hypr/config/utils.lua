local M = {}

local window_rule_counter = 0
local layer_rule_counter = 0

local function bool_value(value)
  return value == "on" or value == "true" or value == "1"
end

local function next_window_rule_name()
  window_rule_counter = window_rule_counter + 1
  return "compat-window-rule-" .. window_rule_counter
end

local function next_layer_rule_name()
  layer_rule_counter = layer_rule_counter + 1
  return "compat-layer-rule-" .. layer_rule_counter
end

function M.dispatch_all(...)
  local dispatchers = { ... }
  return function()
    for _, dispatcher in ipairs(dispatchers) do
      hl.dispatch(dispatcher)
    end
  end
end

function M.window_rule(effect, match, name)
  local key, value = effect:match("^(%S+)%s*(.*)$")
  local rule = {
    name = name or next_window_rule_name(),
    match = match or {},
  }

  if key == "float" or key == "tile" or key == "fullscreen" or key == "center" or key == "pseudo" or key == "pin" or key == "no_initial_focus" or key == "no_blur" or key == "keep_aspect_ratio" then
    rule[key] = bool_value(value)
  elseif key == "border_size" or key == "rounding" then
    rule[key] = tonumber(value)
  elseif key == "suppress_event" or key == "idle_inhibit" or key == "opacity" or key == "tag" or key == "workspace" or key == "move" or key == "size" then
    rule[key] = value
  else
    error("Unhandled window rule effect: " .. effect)
  end

  hl.window_rule(rule)
end

function M.layer_rule(effect, match, name)
  local key, value = effect:match("^(%S+)%s*(.*)$")
  local rule = {
    name = name or next_layer_rule_name(),
    match = match or {},
  }

  if key == "blur" then
    rule.blur = bool_value(value)
  elseif key == "ignore_alpha" then
    rule.ignore_alpha = tonumber(value)
  else
    error("Unhandled layer rule effect: " .. effect)
  end

  hl.layer_rule(rule)
end

return M
