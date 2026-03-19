{ config, pkgs, ... }:
let
  tree-sitter-bin = pkgs.stdenv.mkDerivation rec {
    pname = "tree-sitter-bin";
    version = "0.26.7";
	sha = "sha256:4367a46bc8abbb8328d6efbeb26e86807af0a3a7e462548a3924f87289ee1e9c";

    # Download the pre-compiled binary from GitHub Releases
    src = pkgs.fetchurl {
      url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz";
      hash = sha;
    };

    # We need gzip to decompress the .gz file
    nativeBuildInputs = [ pkgs.gzip ];

    # Since it's just a single compressed file, we don't 'unpack' like a zip
    unpackPhase = ''
      gunzip -c $src > tree-sitter
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp tree-sitter $out/bin/
      chmod +x $out/bin/tree-sitter
    '';

    # Required for pre-compiled binaries to run on NixOS
    # This points the binary to the correct interpreter (ld-linux)
    postFixup = ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/tree-sitter
    '';
  };

in {

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    package = pkgs.neovim; # This will now be the nightly version automatically

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
      tree-sitter-bin
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
