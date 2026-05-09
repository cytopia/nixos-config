{ inputs, ... }:
{
  # Import individual overlays and pass inputs if they need them
  colorpicker = import ./colorpicker.nix;
}
