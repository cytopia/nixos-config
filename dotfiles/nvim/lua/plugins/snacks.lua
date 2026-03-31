return {
  "folke/snacks.nvim",
  opts = {
    -- This moves status column to the left of line numbers
    -- Also check ../config/options.lua
    statuscolumn = { enabled = false },
    picker = {
      sources = {
        explorer = {
          win = {
            list = {
              keys = {
                -- This remaps <C-n> to close the explorer when the list is focused
                ["<C-n>"] = "close",
              },
            },
            input = {
              keys = {
                -- This remaps <C-n> to close the explorer when the search bar is focused
                ["<C-n>"] = { "close", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
}
