local wallust = require("themes.wallust")
local utils = require("config.utils")
local performance_profile = require("config.performance-profile")

local performance_mode = performance_profile.enabled

hl.config({
	general = {
		border_size = 3,
		gaps_in = 4,
		gaps_out = 5,
		col = {
			active_border = {
				colors = { wallust.color12, wallust.color11, wallust.color9, wallust.color7 },
				angle = 45,
			},
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
			enabled = not performance_mode,
			range = 20,
			render_power = 3,
			color = "rgba(10101099)",
			-- color = wallust.color12,
			-- color_inactive = wallust.color10,
		},

		blur = {
			enabled = not performance_mode,
			size = 3,
			passes = 3,
			xray = true,
			ignore_opacity = true,
			vibrancy = 0.2,
			popups = true,
		},
	},

	animations = {
		enabled = not performance_mode,
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		new_status = "master",
	},

	misc = {
		font_family = "Fira Sans",
		focus_on_activate = false,
		vrr = 2,
	},

	group = {
		col = {
			border_active = wallust.color15,
		},
		groupbar = {
			col = {
				active = wallust.color0,
			},
		},
	},
})


-- Increasing stiffness per https://github.com/hyprwm/Hyprland/issues/15494 and https://github.com/hyprwm/Hyprland/pull/15499. 
-- hl.curve("easy", { type = "spring", mass = 1, stiffness = 75.2633, dampening = 15.8273644 })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 258.2633, dampening = 21.8273644 })
local curves = {
	{ "wind", { 0.05, 0.9 }, { 0.1, 1.05 } },
	{ "winIn", { 0.1, 1.1 }, { 0.1, 1.1 } },
	{ "winOut", { 0.3, -0.3 }, { 0, 1 } },
	{ "liner", { 1, 1 }, { 1, 1 } },
	{ "overshot", { 0.05, 0.9 }, { 0.1, 1.05 } },
	{ "smoothOut", { 0.5, 0 }, { 0.99, 0.99 } },
	{ "smoothIn", { 0.5, -0.5 }, { 0.68, 1.5 } },
}

for _, curve in ipairs(curves) do
	hl.curve(curve[1], {
		type = "bezier",
		points = { curve[2], curve[3] },
	})
end

local animations = {
	-- { leaf = "windows", enabled = true, speed = 2, bezier = "wind", style = "slide" },
	-- { leaf = "windowsIn", enabled = true, speed = 2, bezier = "smoothIn", style = "slide" },
	-- { leaf = "windowsOut", enabled = true, speed = 2, bezier = "smoothOut", style = "slide" },
    -- { leaf = "global", enabled = true, speed = 10, bezier = "default" },
	{ leaf = "windows", enabled = true, speed = 2.0, spring = "easy" },
	{ leaf = "windowsIn", enabled = true, speed = 2.0, spring = "easy", style = "slide up" },
	{ leaf = "windowsOut", enabled = true, speed = 2.0, spring = "easy", style = "slide" },
	{ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "wind", style = "slide" },
	{ leaf = "border", enabled = true, speed = 1, bezier = "liner" },
	{ leaf = "borderangle", enabled = not performance_mode, speed = performance_mode and 1 or 80, bezier = "liner", style = not performance_mode and "loop" or nil },
	{ leaf = "fade", enabled = true, speed = 2, bezier = "smoothOut" },
	{ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "overshot" },
	{ leaf = "workspacesIn", enabled = true, speed = 3.5, bezier = "winIn", style = "slide" },
	{ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "winOut", style = "slide" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

hl.workspace_rule({ workspace = "w[t1]", gaps_out = 1, gaps_in = 0 })
hl.workspace_rule({ workspace = "w[tg1]", gaps_out = 1, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 1, gaps_in = 1 })

utils.window_rule("border_size 3", { float = false, workspace = "w[t1]" }, "smart-gaps-tiled-border")
utils.window_rule("rounding 12", { float = true, workspace = "w[t1]" }, "smart-gaps-floating-rounding")
utils.window_rule("border_size 0", { float = false, workspace = "w[tg1]" }, "smart-gaps-tiled-group-border")
utils.window_rule("rounding 0", { float = false, workspace = "w[tg1]" }, "smart-gaps-tiled-group-rounding")
utils.window_rule("border_size 0", { float = false, workspace = "f[1]" }, "smart-gaps-fullscreen-border")
utils.window_rule("rounding 0", { float = false, workspace = "f[1]" }, "smart-gaps-fullscreen-rounding")
