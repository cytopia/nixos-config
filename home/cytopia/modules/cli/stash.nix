{  pkgs, inputs, ... }:
let
  # Create a shortcut for the stash package
  stashPkg = inputs.stash.packages.${pkgs.stdenv.hostPlatform.system}.stash;
in {
  home.packages = with pkgs; [
    stashPkg
  ];
}



