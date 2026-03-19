# overlays/treesitter.nix
inputs: final: prev: {
  # pkgs.custom.tree-sitter
  # This creates 'pkgs.custom' if it doesn't exist, or merges with it if it does
  custom = (prev.custom or {}) // {
    tree-sitter = final.callPackage ../pkgs/tree-sitter/default.nix {};
  };
}
