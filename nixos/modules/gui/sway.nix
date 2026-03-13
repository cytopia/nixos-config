{ config, pkgs, ... }:

let
  unstable = import <unstable> { config = config.nixpkgs.config; };
in
{

  ###
  ### Sway
  ###
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # necessary for GTK app scaling/theming
    #extraOptions = [ "--unsupported-gpu" ];  # only if using nvidia
    extraPackages = with pkgs; [
      swaylock-effects
      swayidle
      swaybg
    ];
  };

  # Required for screen locking (System level only)
  security.pam.services.swaylock = {};

  # Check if required
  services.dbus.enable = true;
  security.polkit.enable = true;

  # Sway usually sets these, but keeping them here ensures
  # XDG portals choose the correct "Sway" backend.
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
  };

  environment.systemPackages = with pkgs; [
    # Terminal & UI
    foot
    waybar
    unstable.ironbar
    unstable.i3status-rust
    fuzzel
    tofi
    wmenu

    # Notifications (Pick one: SwayNC is more modern)
    mako
    swaynotificationcenter
    libnotify # Provides 'notify-send'

    # image viewer
	swayimg

    # Clipboard & Screenshots
    wl-clipboard
    cliphist
    grim
    slurp
    wf-recorder

    # System Utilities
    kanshi        # Auto-configures monitors when plugged in
    brightnessctl
    iwmenu        # Wifi menu for TTY/Wayland
    procps        # Provides 'ps', 'uptime', etc.

    # tray icons
    libappindicator-gtk3  # check if this is needed
    networkmanagerapplet
    blueman
  ];
}
