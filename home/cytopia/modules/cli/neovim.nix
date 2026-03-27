{ pkgs, ... }:

let
  # Available LSPs, linters and formatters:
  #   https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  #   https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
  #   https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
  languageSupport = {
    nix = {
      lsp = [ pkgs.nixd ];
      linter = [ pkgs.statix ];
      formatter = [ pkgs.nixfmt-rfc-style ];
    };
    lua = {
      lsp = [ pkgs.lua-language-server ];
      linter = [ pkgs.selene ];
      formatter = [ pkgs.stylua ];
    };
    python = {
      lsp = [ pkgs.basedpyright ];
      linter = [
        pkgs.ruff
        pkgs.mypy
      ];
      formatter = [ pkgs.ruff ];
    };
    bash = {
      lsp = [ pkgs.bash-language-server ];
      linter = [ pkgs.shellcheck ];
      formatter = [ pkgs.shfmt ];
    };
    terraform = {
      lsp = [ pkgs.terraform-ls ];
      linter = [ pkgs.tflint ];
      formatter = [ pkgs.terraform ];
    };
    terragrunt = {
      lsp = [ ];
      linter = [ ];
      formatter = [ pkgs.terragrunt ];
    };
    json = {
      lsp = [ pkgs.biome ];
      linter = [ pkgs.biome ];
      formatter = [ pkgs.biome ];
    };
    # TODO: biome support is under development
    yaml = {
      lsp = [ pkgs.yaml-language-server ];
      linter = [
        pkgs.yamllint
        pkgs.actionlint
      ];
      formatter = [ pkgs.yamlfmt ];
    };
  };
  # Gather all packages to be added to extraPackages
  languagePackages =
    languageSupport.nix.lsp
    ++ languageSupport.nix.linter
    ++ languageSupport.nix.formatter
    ++ languageSupport.lua.lsp
    ++ languageSupport.lua.linter
    ++ languageSupport.lua.formatter
    ++ languageSupport.python.lsp
    ++ languageSupport.python.linter
    ++ languageSupport.python.formatter
    ++ languageSupport.bash.lsp
    ++ languageSupport.bash.linter
    ++ languageSupport.bash.formatter
    ++ languageSupport.terraform.lsp
    ++ languageSupport.terraform.linter
    ++ languageSupport.terraform.formatter
    ++ languageSupport.terragrunt.lsp
    ++ languageSupport.terragrunt.linter
    ++ languageSupport.terragrunt.formatter
    ++ languageSupport.json.lsp
    ++ languageSupport.json.linter
    ++ languageSupport.json.formatter
    ++ languageSupport.yaml.lsp
    ++ languageSupport.yaml.linter
    ++ languageSupport.yaml.formatter;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # aliases
    viAlias = false;
    vimAlias = true;
    vimdiffAlias = true;

    withRuby = true;
    withPython3 = true;
    withNodeJs = true;

    package = pkgs.custom.neovim-nightly; # custom overlay

    extraLuaPackages = luaPkgs: with luaPkgs; [ luarocks ];
    #extraPython3Packages = pyPkgs: with pyPkgs; [ ];

    extraPackages =
      with pkgs;
      [
        # LazyVim requirements
        git
        ripgrep
        fd
        fzf
        curl

        # LazyVim luarocks
        lua5_1
        luarocks

        # LazyVim nvim-treesitter
        clang
        custom.tree-sitter
        gnutar

        # LazyVim LazyGit
        lazygit
      ]
      ++ languagePackages;
  };
}
