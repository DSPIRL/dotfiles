local function workspace_path()
	return vim.fn.getcwd()
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
