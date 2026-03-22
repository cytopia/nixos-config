{  pkgs, inputs, ... }:
let
  # Create a shortcut for the stash package
  # Clipboard manager for Sway that supports images
  stashPkg = inputs.stash.packages.${pkgs.stdenv.hostPlatform.system}.stash;
in {
  home.packages = with pkgs; [
    stashPkg
  ];
}



