return {
  "folke/snacks.nvim",
  opts = {
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
