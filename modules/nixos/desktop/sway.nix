{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.sway;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.desktop.sway = {
    enable = lib.mkEnableOption "Sway Wayland Compositor";

    enableXwayland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enables XWayland";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        swaylock # Screen locker (Base PAM service in wayland.nix)
        swayidle # Idle management daemon
        fuzzel # App launcher/Menu
        foot # Fast, Wayland-native terminal
        mako # Lightweight notification daemon
        libnotify # Provides 'notify-send'
      ];
      description = "Extra packages to install specifically for the Sway environment.";
    };

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "The default terminal emulator for Sway environment variables.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- INHERITANCE: THE WAYLAND BASE ---
    # We enable the base Wayland module and pass it the Sway-specific portal package.
    mySystem.desktop.wayland = {
      enable = true;
      enableXwayland = cfg.enableXwayland;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    };

    # --- SWAY CORE ---
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # Required for GTK themes and portal synchronization

      xwayland.enable = cfg.enableXwayland;
      # We inject the chosen packages into the system environment
      extraPackages = cfg.extraPackages;
    };

    # --- SWAY SPECIFIC PORTAL CONFIG ---
    # We use lib.mkForce here to override the default 'gtk'-only
    # configuration provided by the built-in NixOS sway module.
    # We tell the system to use 'wlr' first for Sway, then 'gtk' as a fallback.
    xdg.portal = {
      wlr.enable = true;
      #config.sway.default = lib.mkForce [ "wlr" "gtk" ];
      config.sway = {
        default = [ "gtk" ]; # Use GTK for most things (files, settings, themes)
        # Use WLR specifically for screen interaction
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };

    # --- HARDWARE INTEGRATION (OPTIONAL BUT BEST PRACTICE) ---
    # If using brightess/volume keys, these allow unprivileged users in the
    # 'video' or 'input' groups to control hardware without sudo.
    services.udev.packages = with pkgs; [
      brightnessctl
    ];

    # --- SWAY ENVIRONMENT ---
    environment.sessionVariables = {
      # Signal to toolkits that this is a Sway session.
      # Some apps use this to decide between 'wlr' or 'gnome' logic.
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";

      # Set the default terminal for apps that look at the environment.
      TERMINAL = cfg.terminal;
    };
  };
}
