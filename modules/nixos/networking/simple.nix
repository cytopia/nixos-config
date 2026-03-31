{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.networking.simple;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.networking.simple = {
    enable = lib.mkEnableOption "NetworkManager with iwd backend";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos-host";
      description = "The hostname for this specific machine.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Set your machine's hostname
    networking.hostName = cfg.hostName;

    # Explicitly disable wpa_supplicant. If this is running,
    # iwd will see "No devices" because the card is busy.
    networking.wireless.enable = false;

    # --- THE CONNECTIVITY ENGINE ---
    networking.networkmanager = {
      enable = true;
      # iwd is faster at scanning and handles roaming better than wpa_supplicant.
      wifi.backend = "iwd";
    };

    # Required daemon for the NM backend choice above.
    networking.wireless.iwd = {
      enable = true;
      settings = {
        # Privacy Tweaks
        # This enables MAC address randomization every time you connect
        # to a new network, making you harder to track in public spaces.
        Network = {
          EnableIPv6 = true;
          RoutePriority = 20;
        };
        General = {
          AddressRandomization = "network";
        };
      };
    };

    # --- THE USER INTERFACE ---
    # ACTION POINT (NixOS): We enable this here to install the 'nm-applet' binary
    # and—critically—to set up the D-Bus/Polkit permissions required for a
    # non-root user to modify system networking.
    #
    # ACTION POINT (Sway/Home-Manager): Do NOT use 'services.network-manager-applet'
    # in Home Manager (it often enters a 'degraded' state on Wayland).
    # Instead, simply add 'exec nm-applet --indicator' to your Sway startup config.
    programs.nm-applet.enable = true;
  };
}
