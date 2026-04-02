-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- -------------------------------------------------------------------------------------------------
-- Markdown
-- -------------------------------------------------------------------------------------------------

-- Disable Markdown rendering
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})


-- -------------------------------------------------------------------------------------------------
-- Mark trailing whitespace
-- -------------------------------------------------------------------------------------------------
vim.api.nvim_set_hl(0, "RedTrailing", { bg = "#ff0000" })

local trailing_space_group = vim.api.nvim_create_augroup("TrailingSpace", { clear = true })

local function apply_trailing_highlight()
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(0) then return end

    -- 1. Guard: If we are in Insert mode, don't apply the highlight
    local mode = vim.fn.mode()
    if mode == "i" or mode == "ic" or mode == "ix" then
      pcall(vim.cmd, "match none")
      return
    end

    -- 2. Guard: Ignore dashboards, explorers, and overlays
    local excluded_fts = { "snacks_dashboard", "alpha", "lazy", "mason", "neo-tree", "snacks_explorer" }
    if vim.bo.buftype ~= "" or not vim.bo.modifiable or not vim.bo.buflisted or vim.tbl_contains(excluded_fts, vim.bo.filetype) then
      pcall(vim.cmd, "match none")
      return
    end

    -- 3. Apply highlight to actual code windows
    vim.cmd([[match RedTrailing /\s\+$/]])
  end)
end

-- Re-evaluate the highlight when entering windows, leaving insert mode, or loading filetypes
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "InsertLeave", "FileType" }, {
  group = trailing_space_group,
  callback = apply_trailing_highlight,
})

-- Forcefully clear the highlight the exact moment you enter Insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
  group = trailing_space_group,
  callback = function()
    pcall(vim.cmd, "match none")
  end,
})
