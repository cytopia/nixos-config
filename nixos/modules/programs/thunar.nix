{ config, pkgs, ... }:


{
  programs.thunar = {
    enable = true;

    plugins = with pkgs.xfce; [
      thunar-volman
      thunar-archive-plugin
      thunar-vcs-plugin
      thunar-media-tags-plugin
    ];
  };

  programs.xfconf.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

# 1. Ensure gvfs is explicitly in system packages
  #environment.systemPackages = with pkgs; [
  #  gvfs
  #];
}

