-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- USER EDITS START --
Snacks.toggle({
	name = "Completion Auto Popup",
	get = function()
		return vim.g.completion_auto_show ~= false
	end,
	set = function(state)
		vim.g.completion_auto_show = state
		if not state and package.loaded["blink.cmp"] then
			require("blink.cmp").hide()
		end
	end,
}):map("<leader>uE")
-- USER EDITS END --
