{ config, pkgs, ... }:


{
  environment.systemPackages = with pkgs; [
    # Utilities
    pciutils
    usbutils
    unzip
    zip
    file
    procps
    killall

    # Essentials
    vim
    git
    curl
    wget
    fastfetch
    tmux
  ];
}
