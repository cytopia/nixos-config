-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Select all
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true })

-- Exit insert mode via jj
vim.keymap.set("i", "jj", "<Esc>", { noremap = false })

-- Keep search always centered
vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

-- Open Explorer (<leader>e)
-- This also requires an overwrite in ../plugins/snacks.lua
vim.keymap.set("n", "<C-n>", function() Snacks.explorer() end, { desc = "Toggle Explorer" })

-- List open buffers (<leader>,)
vim.keymap.set("n", "<C-o>", function() Snacks.picker.buffers() end, { desc = "Buffers" })
-- List all files (<leader><space>)
vim.keymap.set("n", "<C-p>", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
-- Search in all files (<leader>sg)
vim.keymap.set("n", "<C-g>", function() Snacks.picker.grep() end, { desc = "Grep" })
