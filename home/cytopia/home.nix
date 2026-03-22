{ config, pkgs, pkgs-unstable, inputs, username, stateVersion, ... }:

{
  # Basic Home Manager setup
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = stateVersion;


  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports = [
    # --- Modules ---
    ../../../modules/home-manager/bash.nix

    # --- base: theming ---
    ./modules/base/xdg.nix
    ./modules/base/theme.nix
    ./modules/base/key-management.nix

    # --- cli ---
    #./modules/cli/bash.nix
    ./modules/cli/git.nix
    ./modules/cli/zsh.nix
    ./modules/cli/neovim.nix
    ./modules/cli/stash.nix

    # --- gui: messenger ---
    ./modules/gui/signal.nix
    ./modules/gui/slack.nix
    ./modules/gui/telegram.nix

    # --- gui: others ---
    ./modules/gui/image.nix
    ./modules/gui/keepassxc.nix
    ./modules/gui/thunderbird.nix

    ./modules/sway/i3status-rs-modules.nix
    ./modules/sway/volume-control.nix
    ./modules/sway/microphone-control.nix
    ./modules/sway/brightness-control.nix
  ];

  ###
  ### My Modules: bash
  ###
  cytopia.cli.bash = {
    enable = true;
    enableCompletion = true;
    autoAttachTmux = true;

    aliases = {
      use_bat = true;
      use_eza = false;
      extra = {}
    };

    bashrc.extraFile = ./scripts/shell-functions.sh;
  };


  home.packages = with pkgs; [
    pkgs-unstable.devbox
    wlsunset
    burpsuite

    # Work
    saml2aws
    awscli2
    jq
  ];
}
