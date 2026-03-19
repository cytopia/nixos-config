# overlays/default.nix
{ inputs, ... }:

{
  # We export a list of all overlays in this directory
  modifications = [
    (import ./neovim-nightly.nix inputs)
    # You can add more overlays here later like:
    # (import ./discord-overlay.nix inputs)
  ];
}
