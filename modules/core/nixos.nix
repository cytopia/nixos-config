{ config, pkgs, ... }:


{
  ###
  ### NixOS Package / Flakes
  ###

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
