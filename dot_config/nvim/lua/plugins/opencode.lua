return {
    -- Hide opencode terminal buffers from bufferline
    {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = {
            options = {
                custom_filter = function(buf)
                    return vim.bo[buf].filetype ~= "opencode"
                end,
            },
        },
    },

    {
        "nickjvandyke/opencode.nvim",
        version = "*",
        dependencies = {
            {
                "folke/snacks.nvim",
                optional = true,
                ---@module "snacks"
                opts = {
                    input = {},
                    picker = {
                        actions = {
                            opencode_send = function(...)
                                return require("opencode").snacks_picker_send(...)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                                },
                            },
                        },
                    },
                },
            },
        },
        init = function()
            vim.o.autoread = true
        end,
        ---@return opencode.Opts
        opts = function()
            local ok, terminal = pcall(require, "snacks.terminal")
            if not ok then
                return {}
            end

            local opencode_cmd = "opencode --port"
            ---@type snacks.terminal.Opts
            local terminal_opts = {
                start_insert = false,
                auto_insert = false,
                auto_close = false,
                interactive = false,
                win = {
                    position = "right",
                    width = 0.35,
                    height = 0,
                    relative = "editor",
                    enter = false,
                    bo = {
                        buflisted = false,
                        bufhidden = "hide",
                        filetype = "opencode",
                    },
                    wo = {
                        winbar = "",
                    },
                    keys = {
                        -- Window navigation from terminal mode
                        nav_h = { "<C-h>", "<C-\\><C-n><C-w>h", mode = "t", desc = "Go to left window" },
                        nav_j = { "<C-j>", "<C-\\><C-n><C-w>j", mode = "t", desc = "Go to lower window" },
                        nav_k = { "<C-k>", "<C-\\><C-n><C-w>k", mode = "t", desc = "Go to upper window" },
                        nav_l = { "<C-l>", "<C-\\><C-n><C-w>l", mode = "t", desc = "Go to right window" },
                        -- Hide with q in normal mode
                        q = "hide",
                    },
                    on_win = function(win)
                        require("opencode.terminal").setup(win.win)
                        -- Ensure terminal buffer stays unlisted after setup
                        local buf = vim.api.nvim_win_get_buf(win.win)
                        vim.bo[buf].buflisted = false
                    end,
                },
            }

            return {
                server = {
                    start = function()
                        terminal.open(opencode_cmd, terminal_opts)
                    end,
                    stop = function()
                        terminal.get(opencode_cmd, terminal_opts):close()
                    end,
                    toggle = function()
                        terminal.toggle(opencode_cmd, terminal_opts)
                    end,
                },
            }
        end,
        keys = {
            {
                "<leader>aa",
                function()
                    require("opencode").ask("@this: ", { submit = true })
                end,
                mode = { "n", "x" },
                desc = "Ask opencode...",
            },
            {
                "<leader>ae",
                function()
                    require("opencode").select()
                end,
                mode = { "n", "x" },
                desc = "Execute opencode action...",
            },
            {
                "<leader>ai",
                function()
                    require("opencode").toggle()
                end,
                mode = "n",
                desc = "Toggle opencode",
            },
            {
                "<leader>ar",
                function()
                    return require("opencode").operator("@this ")
                end,
                mode = { "n", "x" },
                expr = true,
                desc = "Add range to opencode",
            },
            {
                "<leader>al",
                function()
                    return require("opencode").operator("@this ") .. "_"
                end,
                mode = "n",
                expr = true,
                desc = "Add line to opencode",
            },
            {
                "<leader>ak",
                function()
                    require("opencode").command("session.half.page.up")
                end,
                mode = "n",
                desc = "Scroll opencode up",
            },
            {
                "<leader>aj",
                function()
                    require("opencode").command("session.half.page.down")
                end,
                mode = "n",
                desc = "Scroll opencode down",
            },
        },
    },
}
