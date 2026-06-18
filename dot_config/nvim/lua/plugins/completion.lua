return {
	{
		"saghen/blink.cmp",
		opts = {
			completion = {
				menu = {
					auto_show = function()
						return vim.g.completion_auto_show ~= false
					end,
				},
			},
		},
	},
}
