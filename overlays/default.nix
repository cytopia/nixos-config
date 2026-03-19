# overlays/default.nix
{ inputs, ... }:

{
  # We export a list of all overlays in this directory
  modifications = [
    # 1. Map Neovim Nightly using 'prev.system' to avoid recursion
    (final: prev: {
      custom = (prev.custom or {}) // {
        neovim-nightly = inputs.neovim-nightly.packages.${prev.stdenv.hostPlatform.system}.default;
      };
    })

	(import ./tree-sitter.nix)
    # You can add more overlays here later like:
    # (import ./discord-overlay.nix inputs)
  ];
}
