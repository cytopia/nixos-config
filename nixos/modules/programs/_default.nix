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
    unixtools.netstat
    unixtools.ifconfig
    curl
    wget

    # Essentials
    vim
    git
    tmux
    #fastfetch
  ];
}
