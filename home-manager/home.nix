{ config, pkgs, ... }:

{
  # Basic Home Manager setup
  home.username = "cytopia";
  home.homeDirectory = "/home/cytopia";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Configure flakes
  nix = {
    package pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  imports = [
    ./modules/bash.nix
  ];
}
