-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- No relative line numbers
vim.opt.relativenumber = false

-- Show char count
vim.opt.colorcolumn = "100"

-- always keep 8 lines above/below the cursor visible when scrolling
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 0

-- always wrap text
vim.opt.wrap = true

-- Disable auto formatting
vim.g.autoformat = false

-- Disable animations
vim.g.snacks_animate = false

-- Disable spell check
vim.opt.spell = false

-- This empties the snack status column
-- Also check ../plugins/snacks.lua
vim.opt.statuscolumn = ""

-- Required for LSP, linter and formatter to work
vim.filetype.add({
  filename = {
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
})
