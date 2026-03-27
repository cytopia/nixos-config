return {
  -- 1. Configure LSP Servers (Language Server Protocol)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- https://github.com/neovim/nvim-lspconfig/tree/master/lsp
        nixd = {},
        lua_ls = {},
        basedpyright = {},
        bashls = {},
        terraformls = {},
        biome = {},
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enabled = true },
            },
          },
        },
      },
    },
  },

  -- 2. Configure the Formatters
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        lua = { "stylua" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        terraform = { "terraform_fmt" },
        terragrunt = { "terragrunt_hclfmt" },
        json = { "biome" },
        yaml = { "yamlfmt" },
      },
    },
  },

  -- 3. Configure the Linter
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        nix = { "statix" },
        lua = { "selene" },
        python = { "ruff", "mypy" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
        terraform = { "tflint" },
        json = { "biomejs" },
        yaml = { "yamllint", "actionlint" },
      },
    },
  },

  -- Note: Package installation will be handled by NixOS
  { "mason-org/mason.nvim", enabled = false },
  { "mason-rg/mason-lspconfig.nvim", enabled = false },

  -- 4. Mason - The package manager
  -- Is responsible for installing the binaries/tools that are
  -- required by lsp, formatters and linters.
  --{
  --  "williamboman/mason.nvim",
  --  opts = {
  --    ensure_installed = {
  --      -- LSP
  --      "lua-language-server", -- Required for lua_ls
  --      "pyright", -- Required for pyright
  --      "bash-language-server", -- Required for bashls

  --      -- Formatters
  --      "stylua",
  --      "shfmt",

  --      -- Linter
  --      "shellcheck", -- Required by shellcheck
  --      "flake8", -- Required by by flake8
  --      "prettierd",
  --    },
  --  },
  --},
}
