return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			preset = "obsidian",
			checkbox = {
				enabled = true,
				unchecked = {
					icon = "󰄱 ",
					highlight = "RenderMarkdownUnchecked",
				},
				checked = {
					icon = " ",
					highlight = "RenderMarkdownChecked",
				},
				custom = {
					tilde = {
						raw = "[~]",
						rendered = "󰰱 ",
						highlight = "RenderMarkdownWarn",
					},
					important = {
						raw = "[!]",
						rendered = " ",
						highlight = "RenderMarkdownError",
					},
					right_arrow = {
						raw = "[>]",
						rendered = " ",
						highlight = "RenderMarkdownInfo",
					},
				},
			},
		},
	},
}
