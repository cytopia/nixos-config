{
  pkgs,
  pkgs-unstable,
  username,
  appScaleFactor,
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
  ### My Modules: gui
  ###
  cytopia.gui.signal-desktop = {
    enable = true;
    scalingFactor = appScaleFactor;
  };
  cytopia.gui.telegram-desktop = {
    enable = true;
    scalingFactor = appScaleFactor;
  };
 cytopia.gui.slack = {
    enable = true;
    scalingFactor = appScaleFactor;
  };

  ###
  ### My Modules: ui
  ###
  cytopia.ui.theme = {
    enable = true;
    scalingFactor = appScaleFactor;
  };

  ###
  ### Additional packages
  ###
  home.packages = with pkgs; [
    wlsunset # redshift
    custom.colorpicker
    burpsuite

    # media
    vlc
    mpv
    shotcut

    # productive
    pkgs-unstable.devbox
    gum
    saml2aws
    awscli2
    lens
    jq
    yq

    # Monitoring
    htop
    btop
    nvtopPackages.intel
  ];
}
