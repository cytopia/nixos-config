return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- Overwrite some colors
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        -- 1. Change ONLY the main text area background
        hl.Normal.bg = "#1E2030"
        hl.NormalNC.bg = "#1E2030"

        if hl.EndOfBuffer then
          hl.EndOfBuffer.bg = "#1E2030"
        end

        -- 2. Force the left gutter to keep the original Tokyonight background (c.bg)
        hl.SignColumn.bg = c.bg
        hl.LineNr.bg = c.bg
        hl.CursorLineNr.bg = c.bg
        hl.FoldColumn.bg = c.bg

        -- 3. Ensure GitSigns in the gutter also use the original background
        if hl.GitSignsAdd then
          hl.GitSignsAdd.bg = c.bg
        end
        if hl.GitSignsChange then
          hl.GitSignsChange.bg = c.bg
        end
        if hl.GitSignsDelete then
          hl.GitSignsDelete.bg = c.bg
        end
      end,
    },
  },
}
