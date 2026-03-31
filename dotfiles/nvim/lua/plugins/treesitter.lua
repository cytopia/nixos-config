return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- LazyVim config for treesitter
      indent = { enable = true }, ---@type lazyvim.TSFeat
      highlight = { enable = true }, ---@type lazyvim.TSFeat
      folds = { enable = true }, ---@type lazyvim.TSFeat
      -- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
      ensure_installed = {
        -- Shell scripting --
        "awk",
        "bash",
        "fish",
        "zsh",
        "jq",

        -- DevOps --
        "dockerfile",
        "hcl",
        "helm",
        "nginx",
        "terraform",

        -- Specific Config --
        "editorconfig",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "ssh_config",
        "tmux",
        "xresources",

        -- Generic Config --
        "ini",
        "json",
        "toml",
        "xml",
        "yaml",

        -- Webdev --
        "css",
        "html",
        "javascript",
        "jsdoc",
        "markdown",
        "markdown_inline",
        "sql",
        "tsx",
        "typescript",

        -- Programming --
        "c",
        "cpp",
        "go",
        "lua",
        "luadoc",
        "luap",
        "make",
        "nix",
        "python",
        "rust",
        "vim",
        "vimdoc",

        -- Misc --
        "diff",
        "printf",
        "query",
        "regex",
      },
    },
  },
}
