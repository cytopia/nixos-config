# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:


{
  programs.nix-ld.enable = true;
  imports =
    [
      ./hardware-configuration.nix
      ./nixos/default.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-d9097b1c-d54a-4659-89c9-9393df8e0b2a".device = "/dev/disk/by-uuid/d9097b1c-d54a-4659-89c9-9393df8e0b2a";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "cytopia" ];
    };
  };

  system.stateVersion = "25.11"; # Did you read the comment?
}
