{ inputs, ... }: {
  # Import individual overlays and pass inputs if they need them
  tree-sitter = import ./tree-sitter.nix;
  colorpicker = import ./colorpicker.nix;
  neovim-nightly = import ./neovim-nightly.nix { inherit inputs; };
}
