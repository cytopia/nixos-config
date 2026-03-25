-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Select all
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true })

-- Keep search always centered
vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

-- vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true })
-- vim.keymap.set("i", "<C-j>", "<Down>", { noremap = true })
-- vim.keymap.set("i", "<C-k>", "<Up>", { noremap = true, nowait = true, silent = true })
-- vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true })
