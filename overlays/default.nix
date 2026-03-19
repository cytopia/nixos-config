{ inputs, ... }: {
  # 1. additions: Custom packages added to pkgs
  additions = final: _prev: {
    # It is recommended to put custom packages at the top level
    tree-sitter = final.callPackage ../pkgs/tree-sitter/default.nix {};
  };

  # 2. modifications: Overrides and overlays from other flakes
  modifications = final: prev: {
    neovim-nightly = inputs.neovim-nightly.packages.${prev.system}.default;
  };

  # 3. unstable-packages: Standardized way to access unstable nixpkgs
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}