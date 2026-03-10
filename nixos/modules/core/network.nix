{ config, pkgs, ... }:


{
  # Set hostname
  networking.hostName = "nixbtw";

  # Modern wireless way
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = false;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
}
