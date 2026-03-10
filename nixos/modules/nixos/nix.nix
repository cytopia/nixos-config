{ config, pkgs, ... }:


{
  ###
  ### NixOS Package / Flakes
  ###

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  ###
  ### Home Manager Standalone
  ###

  ## This replaces 'nix-channel --add' and '--update'
  #nix.nixPath = [
  #  # 1. Keep the standard nixpkgs reference
  #  "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"

  #  # 2. Declare the Home Manager channel
  #  "home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz"

  #  # 3. Allow standard channel lookups
  #  "/nix/var/nix/profiles/per-user/root/channels"
  #];
  ## Optional: ensure the home-manager CLI tool is available system-wide
  #environment.systemPackages = [ pkgs.home-manager ];
}

