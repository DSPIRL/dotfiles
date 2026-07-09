local function is_cloudformation(bufnr)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr

    local filename = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr)):lower()
    if
        filename:match("%.template%.ya?ml$")
        or filename:match("%.template%.json$")
        or filename:match("^cloudformation[._-]")
        or filename:match("[._-]cloudformation[._-]")
        or filename:match("^cfn[._-]")
        or filename:match("[._-]cfn[._-]")
    then
        return true
    end

    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return false
    end

    local line_count = math.min(vim.api.nvim_buf_line_count(bufnr), 500)
    local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, line_count, false), "\n")

    return content:find("AWSTemplateFormatVersion", 1, true) ~= nil
        or content:find("AWS::Serverless", 1, true) ~= nil
        or (content:find("Resources", 1, true) ~= nil and content:find("AWS::", 1, true) ~= nil)
end

local function add_linter(opts, filetype, linter)
    opts.linters_by_ft[filetype] = opts.linters_by_ft[filetype] or {}
    if not vim.tbl_contains(opts.linters_by_ft[filetype], linter) then
        table.insert(opts.linters_by_ft[filetype], linter)
    end
end

local function prefer_cfn_formatter(opts, filetype)
    local fallback = opts.formatters_by_ft[filetype]

    opts.formatters_by_ft[filetype] = function(bufnr)
        if is_cloudformation(bufnr) then
            return { "cfn_format" }
        end

        return type(fallback) == "function" and fallback(bufnr) or fallback or {}
    end
end

return {
    {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "cfn-lint" } },
    },
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters = opts.linters or {}
            opts.linters_by_ft = opts.linters_by_ft or {}

            opts.linters.cfn_lint = {
                condition = function(ctx)
                    local bufnr = vim.fn.bufnr(ctx.filename)
                    return bufnr ~= -1 and is_cloudformation(bufnr)
                end,
            }

            add_linter(opts, "yaml", "cfn_lint")
            add_linter(opts, "json", "cfn_lint")
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters = opts.formatters or {}
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters.cfn_format = {
                command = "cfn-format",
                args = { "--write", "$FILENAME" },
                stdin = false,
            }

            prefer_cfn_formatter(opts, "yaml")
            prefer_cfn_formatter(opts, "json")
        end,
    },
}
