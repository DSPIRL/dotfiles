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
			local silicon = require("nvim-silicon")
			local fallback_language = "typescript"

			local function add_language_attempt(attempts, seen, language, is_fallback)
				if not language or language == "" or seen[language] then
					return
				end

				seen[language] = true
				table.insert(attempts, { language = language, is_fallback = is_fallback })
			end

			local function get_output_location()
				if not silicon.filename then
					return "the location specified in your config file"
				end

				local filename = tostring(silicon.filename)
				if vim.startswith(filename, "~") then
					return filename
				elseif vim.startswith(filename, "./") then
					return vim.fn.getcwd() .. string.sub(filename, 2)
				else
					return filename
				end
			end

			local function notify_success(options, ret)
				if not silicon.message then
					silicon.message = ""
				end

				if options.to_clipboard then
					vim.notify(
						"silicon put the image on the clipboard." .. silicon.message,
						vim.log.levels.INFO,
						{ title = "nvim-silicon" }
					)
				else
					ret.location = get_output_location()
					vim.notify(
						"silicon generated an image at " .. ret.location .. "." .. silicon.message,
						vim.log.levels.INFO,
						{ title = "nvim-silicon" }
					)
				end
			end

			local function run_silicon(cmdline, lines)
				local code = vim.fn.system(cmdline, lines)
				return string.gsub(code, "\n", "")
			end

			silicon.cmd = function(args, options)
				local base_cmdline = silicon.get_arguments(args, options)
				local lines
				lines, base_cmdline = silicon.format_lines(base_cmdline, args, options)

				local attempts = {}
				local seen = {}

				if options.language then
					local language = options.language
					if type(language) == "function" then
						language = language()
					end

					add_language_attempt(attempts, seen, language, false)
				elseif options.disable_defaults then
					table.insert(attempts, { language = nil, is_fallback = false })
				else
					add_language_attempt(attempts, seen, vim.bo.filetype, false)
					add_language_attempt(
						attempts,
						seen,
						vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":e"),
						false
					)
					add_language_attempt(attempts, seen, fallback_language, true)
				end

				local ret = {}
				for _, attempt in ipairs(attempts) do
					local cmdline = vim.deepcopy(base_cmdline)
					if attempt.language then
						table.insert(cmdline, "--language")
						table.insert(cmdline, attempt.language)
					end

					if options.debug then
						print("silicon cmdline: " .. silicon.utils.dump(cmdline))
					end

					ret.language = attempt.language
					ret.code = run_silicon(cmdline, lines)

					if ret.code == "" then
						if attempt.is_fallback then
							vim.notify(
								"silicon could not use the filetype or extension; used fallback language '"
									.. fallback_language
									.. "'.",
								vim.log.levels.WARN,
								{ title = "nvim-silicon" }
							)
						end

						notify_success(options, ret)
						return ret
					end
				end

				vim.notify(
					"silicon returned with: " .. (ret.code or "unknown error"),
					vim.log.levels.WARN,
					{ title = "nvim-silicon" }
				)

				return ret
			end

			silicon.setup({
				font = "Hack Nerd Font=34;Jetbrains Mono Nerd Font=34;Noto Color Emoji=34",
				theme = "Dracula",
				-- background = "#94e2d5",
				background_image = string.format("%s/.config/silicon/background.jpeg", home),
				to_clipboard = true,
				no_window_controls = true,
				pad_horiz = 70,
				pad_vert = 70,
				shadow_offset_x = 0,
				-- Keep nil so the command wrapper can try filetype, extension, then fallback_language.
				language = nil,
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
