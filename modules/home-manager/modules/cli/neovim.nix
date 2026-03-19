{ config, pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    package = pkgs.neovim-nightly; # custom overlay

    # aliases
    viAlias = false;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      # defaults
      git
      curl
      luarocks
      # for treesitter
      tree-sitter  # comes from pkgs/
      gcc
      # For fzf-lua
      fzf
      ripgrep
      fd
    ];

    # Failed to run healthcheck for "nvim-treesitter" plugin. Exception:
    # ...-unwrapped-0.11.6/share/nvim/runtime/lua/vim/version.lua:174: attempt to index local 'version' (a nil value)
    #plugins = with pkgs.vimPlugins; [
    #  nvim-treesitter.withAllGrammars
    #];
  };
}
