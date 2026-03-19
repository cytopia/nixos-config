# This file takes our flake inputs so it can access the nightly source
# 'final' is the package set after all overlays (use for dependencies)
# 'prev' is the package set before this overlay (the "original")
inputs: final: prev:
let
  # This is the 'set' containing all the nightly variants
  nightlySet = inputs.neovim-nightly.overlays.default final prev;
in {
  # pkgs.custom.neovim-nightly
  # This creates 'pkgs.custom' if it doesn't exist, or merges with it if it does
  custom = (prev.custom or {}) // {
    neovim-nightly = nightlySet.neovim;
    neovim-nightly-unwrapped = nightlySet.neovim-unwrapped;
  };
}
