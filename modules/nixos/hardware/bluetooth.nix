{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.hardware.bluetooth;
in
{
  ###
  ### 1. OPTIONS (The Control Panel)
  ###
  options.mySystem.hardware.bluetooth = {
    enable = lib.mkEnableOption "Optimized Bluetooth support (BlueZ 5+)";

    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically power on the default Bluetooth controller during boot.";
    };

    enableExperimental = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable experimental features in the BlueZ daemon.
        Highly recommended, as it is required to show battery percentages for modern headphones/controllers.
      '';
    };

    enableGUI = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the Blueman GTK applet.
        Only set this to true if you are using a standalone Window Manager (like Sway, Hyprland, or i3).
        Do NOT enable this if you use GNOME or KDE, as they provide their own native Bluetooth managers.
      '';
    };

    enableDiagnostics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install CLI diagnostic and pairing tools (bluetoothctl, bluez-tools).";
    };
  };


  ###
  ### 2. CONFIGURATION (The Logic)
  ###
  config = lib.mkIf cfg.enable {

    # --- CORE BLUETOOTH STACK ---
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;

      # Configuration Injection
      # We inject custom settings directly into /etc/bluetooth/main.conf
      # https://github.com/bluez/bluez/blob/master/src/main.conf
      settings = {
        General = {
          # Pitfall prevented: By default, BlueZ hides battery levels for LE (Low Energy) devices.
          # Flipping this to true allows your desktop environment to read headphone battery levels.
          Experimental = lib.mkIf cfg.enableExperimental true;

          # Fast Connect
          # Significantly speeds up connection times for previously paired devices like mice and keyboards.
          FastConnectable = true;
        };
        Policy = {
          # Enable all controllers when they are found. This includes
          # adapters present on start as well as adapters that are plugged
          # in later on. Defaults to 'true'.
          AutoEnable = true;
          # Pitfall prevented: BlueZ is notoriously bad at automatically reconnecting
          # devices that briefly lose signal (like walking into another room with headphones).
          # These two lines force the daemon to aggressively try to reconnect 7 times
          # at exponential intervals (1s, 2s, 4s, 8s, etc.) before giving up.
          ReconnectAttempts = 7;
          ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        };
      };
    };

    # --- DESKTOP GUI ---
    # Blueman Service
    # Reason: Standalone window managers lack a way to securely prompt for Bluetooth PINs
    # when pairing new devices. Blueman handles both the system tray UI and the security agent.
    services.blueman = lib.mkIf cfg.enableGUI {
      enable = true;
    };

    # --- TOOLS & DIAGNOSTICS ---
    environment.systemPackages = lib.mkIf cfg.enableDiagnostics (with pkgs; [
      bluez         # Provides 'bluetoothctl' (The core CLI manager)
      bluez-tools   # Provides 'bt-device', 'bt-agent' (Great for advanced scripting and debugging)
    ]);
  };
}
