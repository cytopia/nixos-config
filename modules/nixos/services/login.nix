{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.services.login;

  # A generic wrapper that sets Wayland vars for any compositor
  session-wrapper = pkgs.writeShellScript "greetd-session-wrapper" ''

    #exec "$@" 2> /tmp/wayland.errors>(${pkgs.systemd}/bin/systemd-cat -t wayland-session)
    exec "$@" 2> /tmp/wayland.errors
  '';

  # Command construction using absolute store paths
  tuigreet-cmd = lib.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"

    #"--remember"
    #"--remember-user-session"
    "--theme '${cfg.theme}'"
    "--greeting '${cfg.greeting}'"

    "--cmd '${session-wrapper} ${cfg.defaultSession}'"
    #"--sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions"
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

    # Keep the TUI clean from kernel "noise" during password entering on greetd
    boot.kernelParams = [
      "quiet"
      "splash"
    ];

    # If Gnome Keyring is enabled (somehwere), tell PAM to unlock the keyring automatically.
    security.pam.services.greetd.enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;

    # The login service
    services.greetd = {
      enable = true;

      settings = {
        default_session = {
          command = tuigreet-cmd;
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
