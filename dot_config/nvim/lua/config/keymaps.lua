-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- USER EDITS START --

local completion_auto_popup = Snacks.toggle({
	id = "completion_auto_popup",
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
})

completion_auto_popup:map("<leader>uE")

local zen_profile_state

local function restore_zen_profile()
	if not zen_profile_state then
		return
	end

	local state = zen_profile_state
	zen_profile_state = nil

	Snacks.toggle.diagnostics():set(state.diagnostics)
	if state.inlay_hints ~= nil and vim.lsp.inlay_hint and vim.api.nvim_buf_is_valid(state.bufnr) then
		vim.lsp.inlay_hint.enable(state.inlay_hints, { bufnr = state.bufnr })
	end
	completion_auto_popup:set(state.completion_auto_popup)
	Snacks.toggle.dim():set(state.dim)
end

Snacks.toggle({
	id = "zen_profile",
	name = "Zen Profile",
	get = function()
		return zen_profile_state ~= nil
	end,
	set = function(state)
		if not state then
			if Snacks.zen.win and Snacks.zen.win:valid() then
				Snacks.zen.win:close()
			end
			restore_zen_profile()
			return
		end

		if zen_profile_state then
			return
		end

		local bufnr = vim.api.nvim_get_current_buf()
		zen_profile_state = {
			bufnr = bufnr,
			diagnostics = Snacks.toggle.diagnostics():get(),
			inlay_hints = vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) or nil,
			completion_auto_popup = completion_auto_popup:get(),
			dim = Snacks.toggle.dim():get(),
		}

		Snacks.toggle.diagnostics():set(false)
		if vim.lsp.inlay_hint then
			vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
		end
		completion_auto_popup:set(false)
		Snacks.toggle.dim():set(false)

		if Snacks.zen.win and Snacks.zen.win:valid() then
			Snacks.zen.win:on("WinClosed", restore_zen_profile, { win = true })
			return
		end

		Snacks.zen({
			toggles = {
				dim = false,
				git_signs = false,
				mini_diff_signs = false,
			},
			on_close = restore_zen_profile,
		})
	end,
}):map("<leader>zp")
-- USER EDITS END --
