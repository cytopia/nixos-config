{ pkgs, ... }:

{
  # Set your machine's hostname
  networking.hostName = "host";

  # 1. Enable NetworkManager
  networking.networkmanager.enable = true;

  # 2. Tell NetworkManager to use iwd as the WiFi backend
  networking.networkmanager.wifi.backend = "iwd";

  # 3. Explicitly enable the iwd daemon
  networking.wireless.iwd.enable = true;

  # Enable nm-applet and keyring for password storage
  programs.nm-applet.enable = true;
  services.gnome.gnome-keyring.enable = true;
}
