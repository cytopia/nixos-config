{ config, pkgs, inputs, stateVersion, ... }:

{
  # Basic Home Manager setup
  home.username = "cytopia";
  home.homeDirectory = "/home/cytopia";
  home.stateVersion = stateVersion;


  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports = [
    ./modules/default.nix

    # --- base: theming ---
    ./modules/base/xdg.nix
    ./modules/base/theme.nix
    ./modules/base/key-management.nix

    # --- cli ---
    #./modules/cli/ssh-agent.nix
    ./modules/cli/bash.nix
    ./modules/cli/git.nix
    ./modules/cli/zsh.nix
    ./modules/cli/neovim.nix

    # --- gui: messenger ---
    ./modules/gui/signal.nix
    ./modules/gui/slack.nix
    ./modules/gui/telegram.nix

    # --- gui: others ---
    #./modules/gui/chromium.nix
    ./modules/gui/image.nix
    ./modules/gui/keepassxc.nix
    ./modules/gui/thunderbird.nix

    ./modules/sway/i3status-rs-modules.nix
    ./modules/sway/volume-control.nix
    ./modules/sway/microphone-control.nix
    ./modules/sway/brightness-control.nix
  ];
}
