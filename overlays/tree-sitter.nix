final: prev: {
  # Safely merge into the 'custom' namespace
  custom = (prev.custom or { }) // {
    # callPackage automatically passes dependencies. We use 'final' here
    # so that if you ever override a dependency globally, tree-sitter uses the overridden version.
    tree-sitter = final.callPackage ../pkgs/tree-sitter/default.nix { };
  };
}
