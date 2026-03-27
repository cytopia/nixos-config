return {
  "folke/snacks.nvim",
  opts = {
    picker = {

      -- This applies to ALL pickers (Buffers, Files, Grep, etc.)
      -- win = {
      --   input = {
      --     keys = {
      --       -- Navigate down the list
      --       ["<C-j>"] = { "list_down", mode = { "i", "n" } },
      --       -- Navigate up the list
      --       ["<C-k>"] = { "list_up", mode = { "i", "n" } },
      --     },
      --   },
      -- },

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
