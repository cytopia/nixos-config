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

      # "random" generates a new MAC every time you connect.
      # "stable" generates a unique, persistent MAC per network (usually preferred).
      wifi.macAddress = "stable";
    };

    # Required daemon for the NM backend choice above.
    networking.wireless.iwd = {
      enable = true;
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
