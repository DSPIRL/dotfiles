-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- USER EDITS START --
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.scrolloff = 999
vim.opt.wrapscan = false
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.smarttab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.wrap = true

-- Disable format on save; manual formatting remains available with <leader>cf
vim.g.autoformat = false

-- Disable auto diagnostic (<leader>ud)
vim.diagnostic.enable(false)

-- vim.opt.foldmethod = "indent"
-- USER EDITS END --
