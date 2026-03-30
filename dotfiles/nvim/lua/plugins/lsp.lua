return {
  -- 1. Configure LSP Servers (Language Server Protocol)
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
      servers = {
        nixd = {},
        lua_ls = {},
        basedpyright = {},
        bashls = {},
        terraformls = {},
        biome = {
          cmd = { "biome", "lsp-proxy" },
        },
        docker_language_server = {
          init_options = {
            telemetry = "off", -- "all" | "error" | "off"
            dockercomposeExperimental = {
              composeSupport = true,
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = true },
              kubernetesCRDStore = { enable = true },
              validate = true,
              completion = true,
              format = { enable = false }, -- Let yamlfmt do that.
            },
            redhat = {
              telemetry = {
                enabled = false,
              },
            },
          },
        },
      },
    },
  },

  -- 2. Configure the Linter
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      -- https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
      linters_by_ft = {
        nix = { "statix" },
        lua = { "selene" },
        python = { "ruff", "mypy" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
        terraform = { "tflint" },
        dockerfile = { "hadolint" },
        make = { "checkmake", "mbake" },
        ["yaml.docker-compose"] = { "yamllint" },
        json = { "biomejs" },
        yaml = { "yamllint", "actionlint" },
      },
    },
  },

  -- 3. Configure the Formatters
  {
    "stevearc/conform.nvim",
    opts = {
      -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
      formatters_by_ft = {
        nix = { "nixfmt" },
        lua = { "stylua" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        terraform = { "terraform_fmt" },
        terragrunt = { "terragrunt_hclfmt" },
        dockerfile = { "dockerfmt" },
        make = { "mbake" },
        ["yaml.docker-compose"] = { "yamlfmt" },
        json = { "biome" },
        yaml = { "yamlfmt" },
      },
      formatters = {
        mbake = {
          command = "mbake",
          args = { "format", "--stdin" },
        },
      },
    },
  },

  -- Note: Package installation will be handled by NixOS
  { "mason-org/mason.nvim", enabled = false },
  { "mason-rg/mason-lspconfig.nvim", enabled = false },
}
