# This file takes our flake inputs so it can access the nightly source
# 'final' is the package set after all overlays (use for dependencies)
# 'prev' is the package set before this overlay (the "original")
inputs: final: prev:
let
  # This is the 'set' containing all the nightly variants
  nightlySet = inputs.neovim-nightly.overlays.default final prev;
in {
  # We want the 'neovim' package from within that set
  # We are 'mapping' the flake input to the standard 'neovim' attribute
  neovim = nightlySet.neovim;
}
