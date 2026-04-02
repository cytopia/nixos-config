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
  -- vim.schedule defers the check until LazyVim has fully loaded the UI
  vim.schedule(function()
    -- Failsafe: check if the buffer still exists after the delay
    if not vim.api.nvim_buf_is_valid(0) then return end

    local excluded_fts = { "snacks_dashboard", "alpha", "lazy", "mason", "neo-tree", "snacks_explorer" }

    if vim.bo.buftype ~= "" or not vim.bo.modifiable or not vim.bo.buflisted or vim.tbl_contains(excluded_fts, vim.bo.filetype) then
      pcall(vim.cmd, "match none")
      return
    end

    vim.cmd([[match RedTrailing /\s\+$/]])
  end)
end

-- Added 'FileType' to the list so it catches the dashboard the moment it identifies itself
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "InsertLeave", "FileType" }, {
  group = trailing_space_group,
  callback = apply_trailing_highlight,
})

-- Remove the highlight temporarily while actively typing
vim.api.nvim_create_autocmd("InsertEnter", {
  group = trailing_space_group,
  callback = function()
    pcall(vim.cmd, "match none")
  end,
})
