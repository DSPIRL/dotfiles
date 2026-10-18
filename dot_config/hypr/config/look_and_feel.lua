local utils = require("config.utils")
local M = {}

-- Use dofile, not require: generated palette files must not join Hyprland's
-- config watch list and trigger a full reload when the wallpaper changes.
function M.apply_palette()
  local wallust = dofile(os.getenv("HOME") .. "/.config/hypr/themes/wallust.lua")
  hl.config({
    general = { col = { active_border = {
      colors = { wallust.color12, wallust.color11, wallust.color9, wallust.color7 },
      angle = 45,
    } } },
    group = { col = { border_active = wallust.color15 }, groupbar = { col = { active = wallust.color0 } } },
  })
end

hl.config({
	general = {
		border_size = 2,
		gaps_in = 4,
		gaps_out = 5,
		col = {
			inactive_border = "rgba(00ffff00)",
		},
		resize_on_border = true,
	},

	decoration = {
		rounding = 10,
        rounding_power = 3,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,
		dim_strength = 0.1,
		dim_special = 0.8,

		shadow = {
			range = 20,
			render_power = 3,
			color = "rgba(10101099)",
			-- color = wallust.color12,
			-- color_inactive = wallust.color10,
		},

		blur = {
			size = 3,
			passes = 3,
			xray = true,
			ignore_opacity = true,
			vibrancy = 0.2,
			popups = true,
		},
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		new_status = "master",
		-- Centered workspace mode: a 50%-wide master with slaves on both sides.
		mfact = 0.5,
		orientation = "center",
		slave_count_for_center_master = 2,
	},

	misc = {
		font_family = "Fira Sans",
		focus_on_activate = false,
		vrr = 2,
	},
})


-- Keep the stiffer spring, but damp its bounce without removing it entirely.
hl.curve("easy", { type = "spring", mass = 1, stiffness = 258.2633, dampening = 28 })
local curves = {
	-- Shared timing keeps workspace slides and window rearrangement aligned.
	{ "workspaceSmooth", { 0.22, 1 }, { 0.36, 1 } },
	{ "liner", { 1, 1 }, { 1, 1 } },
	{ "fadeSmooth", { 0.25, 1 }, { 0.5, 1 } },
}

for _, curve in ipairs(curves) do
	hl.curve(curve[1], {
		type = "bezier",
		points = { curve[2], curve[3] },
	})
end

local animations = {
	{ leaf = "windows", enabled = true, speed = 2.0, spring = "easy" },
	{ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "workspaceSmooth", style = "popin 95%" },
	{ leaf = "windowsOut", enabled = true, speed = 2.0, spring = "easy", style = "slide" },
	{ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "workspaceSmooth" },
	{ leaf = "border", enabled = true, speed = 1, bezier = "liner" },
	{ leaf = "borderangle", enabled = false, speed = 80, bezier = "liner", style = "loop" },
	{ leaf = "fade", enabled = true, speed = 2, bezier = "fadeSmooth" },
	{ leaf = "fadeIn", enabled = true, speed = 1.8, bezier = "fadeSmooth" },
	{ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "workspaceSmooth" },
	{ leaf = "workspacesIn", enabled = true, speed = 3.5, bezier = "workspaceSmooth", style = "slide" },
	{ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "workspaceSmooth", style = "slide" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

hl.workspace_rule({ workspace = "w[t1]", gaps_out = 1, gaps_in = 0 })
hl.workspace_rule({ workspace = "w[tg1]", gaps_out = 1, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 1, gaps_in = 1 })

utils.window_rule("border_size 2", { float = false, workspace = "w[t1]" }, "smart-gaps-tiled-border")
utils.window_rule("rounding 12", { float = true, workspace = "w[t1]" }, "smart-gaps-floating-rounding")
utils.window_rule("border_size 0", { float = false, workspace = "w[tg1]" }, "smart-gaps-tiled-group-border")
utils.window_rule("rounding 0", { float = false, workspace = "w[tg1]" }, "smart-gaps-tiled-group-rounding")
utils.window_rule("border_size 0", { float = false, workspace = "f[1]" }, "smart-gaps-fullscreen-border")
utils.window_rule("rounding 0", { float = false, workspace = "f[1]" }, "smart-gaps-fullscreen-rounding")

M.apply_palette()
return M
