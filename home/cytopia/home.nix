{
  pkgs,
  pkgs-unstable,
  username,
  stateVersion,
  ...
}:

{
  # Basic Home Manager setup
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports = [
    # --- Modules ---
    ../../modules/home-manager/default.nix

    # --- base: theming ---
    ./modules/base/xdg.nix
    #./modules/base/theme.nix
    ./modules/base/key-management.nix

    # --- cli ---
    #./modules/cli/bash.nix
    ./modules/cli/git.nix
    ./modules/cli/zsh.nix
    ./modules/cli/neovim.nix
    #./modules/cli/stash.nix  # Weired terminal issues

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
  ### My Modules: cli
  ###
  cytopia.cli.bash = {
    enable = true;
    enableCompletion = true;

    extraRcFile = ./modules/cli/scripts/shell-functions.sh;
    autoAttachTmux = true;

    enableBat = true;
    enableDircolors = true;
    enableDirenv = true;
    enableFzf = true;
    enableStarship = true;

    enableEza = false;
    enableZoxide = false;
  };
  cytopia.cli.fish = {
    enable = true;
    enableCompletion = true;

    #extraRcFile = ./modules/cli/scripts/shell-functions.sh;
    autoAttachTmux = true;

    enableBat = true;
    enableDircolors = true;
    enableDirenv = true;
    enableFzf = true;
    enableStarship = true;

    enableEza = false;
    enableZoxide = false;
  };

  ###
  ### My Modules: ui
  ###
  cytopia.ui.theme.enable = true;

  ###
  ### Additional packages
  ###
  home.packages = with pkgs; [
    pkgs-unstable.devbox
    wlsunset # redshift
    custom.colorpicker
    burpsuite

    # Work
    saml2aws
    awscli2
    jq
    yq

    # Monitoring
    htop
    btop
    nvtopPackages.intel
  ];
}
