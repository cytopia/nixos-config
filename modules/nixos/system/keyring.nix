{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.system.keyring;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.keyring = {
    enable = lib.mkEnableOption "system-wide security and key management";

    keyringEnable = lib.mkEnableOption "Gnome Keyring daemon";
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {
    # 1. Keyring Configuration
    services.gnome.gnome-keyring = lib.mkIf cfg.keyringEnable {
      enable = true;
    };

    # 2. GPG / Identity Tools
    # We install the binaries at system level, but leave the Agent to Home-Manager
    environment.systemPackages = [ pkgs.gnupg ];
    programs.gnupg.agent = {
      enable = false;
    };

    # 3. Security Glue
    # Ensure TTY logins also unlock the keyring
    security.pam.services.login.enableGnomeKeyring = cfg.keyringEnable;
  };
}
