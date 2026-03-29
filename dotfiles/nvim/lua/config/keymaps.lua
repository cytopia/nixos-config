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
-- im.keymap.set("n", "<C-o>", function() Snacks.picker.buffers({current = false}) end, { desc = "Show buffers without current"})
vim.keymap.set("n", "<C-o>", function() Snacks.picker.buffers({
  current = true,
  sort_lastused = true;
  on_show = function(picker)
    picker:action("list_down")
  end,
}) end, { desc = "Show buffers and preselect previous" })

-- List all files (<leader><space>)
vim.keymap.set("n", "<C-p>", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
-- Search in all files (<leader>sg)
vim.keymap.set("n", " C-g>", function() Snacks.picker.grep() end, { desc = "Grep" })

-- Relad configration
vim.keymap.set("n", "<leader>r", function()
  -- Clear the cache for your specific files
  package.loaded["config.autocmds"] = nil
  package.loaded["config.keymaps"] = nil
  package.loaded["config.options"] = nil
  -- Re-run them individually
  require("config.autocmds")
  require("config.keymaps")
  require("config.options")

  -- 4. Re-load everything in the plugins directory
  -- This updates the "specs" that lazy.nvim knows about
  local plugin_files = vim.api.nvim_get_runtime_file("lua/plugins/*.lua", true)
  for _, file in ipairs(plugin_files) do
    -- Convert file path to module name (e.g., plugins.ui)
    local module = file:match("lua/(plugins/.*)%.lua$")
    if module then
      module = module:gsub("/", ".")
      package.loaded[module] = nil
      require(module)
    end
  end
  Snacks.notify.info("Config and Plugins reloaded!", { title = "Config" })
end, { desc = "Reload Full Neovim Config" })
