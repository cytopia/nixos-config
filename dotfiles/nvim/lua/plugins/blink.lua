return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      -- 1. Remove them from the default list
      -- default = { "lsp", "path" },

      -- 2. Explicitly disable the providers so they can't "sneak" back in
      providers = {
        snippets = { enabled = false }, -- Disables bundled snippets
        buffer = { enabled = false }, -- Disables completing words that exist in current file
      },
    },
    -- 3. Disable the "Ghost Text" (the gray text previewing the suggestion)
    -- completion = {
    --   ghost_text = { enabled = true },
    -- },
  },
}
