local function workspace_path()
	return vim.fn.getcwd()
end

local function disable_frontmatter_when_formatting_is_disabled()
	local lazyvim = rawget(_G, "LazyVim")
	if not lazyvim or not lazyvim.format or not lazyvim.format.enabled then
		return false
	end

	return not lazyvim.format.enabled(0)
end

return {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		cmd = {
			"ObsidianBacklinks",
			"ObsidianDailies",
			"ObsidianFollowLink",
			"ObsidianLink",
			"ObsidianLinkNew",
			"ObsidianLinks",
			"ObsidianNew",
			"ObsidianOpen",
			"ObsidianPasteImg",
			"ObsidianQuickSwitch",
			"ObsidianSearch",
			"ObsidianTags",
			"ObsidianTemplate",
			"ObsidianToday",
			"ObsidianToggleCheckbox",
			"ObsidianWorkspace",
		},
		opts = {
			disable_frontmatter = disable_frontmatter_when_formatting_is_disabled,
			workspaces = {
				{
					name = "notes",
					path = workspace_path,
				},
			},
			completion = {
				nvim_cmp = false,
				min_chars = 2,
			},
			picker = {
				name = "telescope.nvim",
			},
			ui = {
				enable = false,
			},
		},
	},
}
