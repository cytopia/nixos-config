{ config, pkgs, ... }:


{
  programs.nix-ld.enable = true;
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/default.nix
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


  system.stateVersion = "25.11"; # Did you read the comment?
}

