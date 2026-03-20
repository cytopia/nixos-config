{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.services.login;

  # A generic wrapper that sets Wayland vars for any compositor
  session-wrapper = pkgs.writeShellScript "greetd-session-wrapper" ''
    # Export essential Wayland environment variables
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=$(basename "$1")
    export XDG_CURRENT_DESKTOP=$XDG_SESSION_DESKTOP

    # Execute the compositor passed as the first argument
    # Redirecting 2>&1 ensures everything hits the systemd journal
    #exec "$@"
	exec "$@" 2> >(${pkgs.systemd}/bin/systemd-cat -t wayland-session)
  '';

  # Command construction using absolute store paths
  tuigreet-cmd = lib.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"
    #"--remember"
    #"--remember-user-session"
    "--theme '${cfg.theme}'"
    "--greeting '${cfg.greeting}'"
    "--cmd ${cfg.defaultSession}" # The default highlighted option
    "--sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions"
  ];
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.services.login = {
    enable = lib.mkEnableOption "Custom greetd with tuigreet";

    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "sway";
      description = "The compositor command to run by default (e.g., 'sway' or 'Hyprland').";
    };

    gnomeKeyring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to initialize Gnome Keyring in the session wrapper.";
      };
      components = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "secrets" ]; # SSH is now optional/omitted by default
        description = "Gnome Keyring components to start (secrets, ssh, pkcs11).";
      };
    };

    vt = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "The virtual terminal to use.";
    };

    greeting = lib.mkOption {
      type = lib.types.str;
      default = "NixOS";
      description = "The welcome message shown in tuigreet.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";
      description = "The tuigreet color scheme.";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Ensure tuigreet is available in the system profile
    #environment.systemPackages = [ pkgs.tuigreet ];

    # Keep the TUI clean from kernel "noise" during password entering on greetd
    boot.kernelParams = [ "quiet" "splash" ];

    # Only enable the system-wide service if our module option is enabled
    services.gnome.gnome-keyring.enable = lib.mkIf cfg.gnomeKeyring.enable true;
    security.pam.services.greetd.enableGnomeKeyring = lib.mkIf cfg.gnomeKeyring.enable true;

    # The login service
    services.greetd = {
      enable = true;

      settings = {
        default_session = {
          command = "${session-wrapper} ${tuigreet-cmd}";
          user = "greeter";
          vt = cfg.vt;
        };
      };
    };

    # Stop the kernel from spitting logs over our pretty UI
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "journal";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
