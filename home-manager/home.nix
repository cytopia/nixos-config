{ config, pkgs, ... }:

{
  # Basic Home Manager setup
  home.username = "cytopia";
  home.homeDirectory = "/home/cytopia";
  home.stateVersion = "25.11";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Configure flakes
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  imports = [
    # --- cli ---
    ./modules/cli/bash.nix
    ./modules/cli/neovim.nix

    # --- gui: theming ---
    ./modules/gui/theme.nix

    # --- gui: messenger ---
    ./modules/gui/signal.nix
    ./modules/gui/slack.nix
    #./modules/gui/telegram.nix

    # --- gui: others ---
    #./modules/gui/chromium.nix
    ./modules/gui/keepassxc.nix
    ./modules/gui/thunderbird.nix

    ./modules/sway/volume-control.nix
    ./modules/sway/microphone-control.nix

  ];
}
