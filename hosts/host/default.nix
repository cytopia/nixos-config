{ config, pkgs, ... }:


{
  programs.nix-ld.enable = true;
  imports =
  [
    ./hardware-configuration.nix
    #../../modules/nixos/default.nix

    # --- Core modules ---
    ./modules/core/network.nix
    ./modules/core/time-locale.nix
    ./modules/core/keyboard.nix
    ./modules/core/users.nix
    ./modules/core/gpu-intel.nix
    ./modules/core/bluetooth.nix
    ./modules/core/sound.nix
    ./modules/core/power-management.nix

    # --- CLI modules ---
    ./modules/cli/vim.nix

    # --- GUI modules ---
    ./modules/gui/fonts.nix
    ./modules/gui/login-manager.nix
    ./modules/gui/display-manager.nix
    ./modules/gui/sway.nix

    # --- Programs ---
    ./modules/programs/_default.nix
    ./modules/programs/chromium.nix
    ./modules/programs/thunar.nix
    ./modules/programs/podman.nix
    ./modules/programs/obs.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "cytopia" ];
    };
  };

  # TODO: Move this somewhere else
  programs.awsvpnclient.enable = true;

  environment.systemPackages = [
    pkgs.steam-run
  ];
  qt.enable = true;

  # Might help chromium errors and screensharing
  fonts.fontconfig.enable = true;


  system.stateVersion = "25.11"; # Did you read the comment?
}

