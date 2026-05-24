local home = os.getenv("HOME")

return {
	{
		"michaelrommel/nvim-silicon",
		lazy = true,
		cmd = "Silicon",
		init = function()
			local wk = require("which-key")
			wk.add({
				mode = { "v" },
				{ "<leader>z", group = "Silicon" },
				{
					"<leader>zc",
					function()
						require("nvim-silicon").clip()
					end,
					desc = "Copy code screenshot to clipboard",
				},
				{
					"<leader>zf",
					function()
						require("nvim-silicon").file()
					end,
					desc = "Save code screenshot as file",
				},
				{
					"<leader>zs",
					function()
						require("nvim-silicon").shoot()
					end,
					desc = "Create code screenshot",
				},
			})
		end,
		config = function()
			require("nvim-silicon").setup({
				font = "FiraCode Nerd Font=34;Hack Nerd Font=34;Jetbrains Mono Nerd Font=34;Noto Color Emoji=34",
				theme = "Dracula",
				-- background = "#94e2d5",
				background_image = string.format("%s/.config/silicon/background.jpeg", home),
				to_clipboard = true,
				no_window_controls = true,
				pad_horiz = 70,
				pad_vert = 70,
				shadow_offset_x = 0,
				language = function()
					return vim.bo.filetype
				end,
				shadow_offset_y = 0,
				shadow_color = nil,
				shadow_blur_radius = 30,
				gobble = true,
				window_title = function()
					return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
					-- num_separator = "\u{258f}",
					-- background_image = "./painted.png",
				end,
			})
		end,
	},
}
