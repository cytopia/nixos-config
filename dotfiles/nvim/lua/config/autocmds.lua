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

-- Function to check if we should highlight or hide
local function apply_trailing_highlight()
  -- List of filetypes to explicitly ignore
  local excluded_fts = { "snacks_dashboard", "alpha", "lazy", "mason", "neo-tree" }

  -- If it's a special buffer OR an excluded filetype, clear the match and stop
  if vim.bo.buftype ~= "" or vim.tbl_contains(excluded_fts, vim.bo.filetype) then
    vim.cmd([[match none]])
    return
  end

  -- Otherwise, apply the red highlight
  vim.cmd([[match RedTrailing /\s\+$/]])
end

-- Trigger the check when entering windows, buffers, or leaving insert mode
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "InsertLeave" }, {
  group = trailing_space_group,
  callback = apply_trailing_highlight,
})

-- Remove the highlight temporarily while actively typing
vim.api.nvim_create_autocmd("InsertEnter", {
  group = trailing_space_group,
  callback = function()
    vim.cmd([[match none]])
  end,
})
