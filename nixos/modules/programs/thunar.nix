{ config, pkgs, ... }:


{
  programs.thunar = {
    enable = true;

    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-vcs-plugin
      thunar-volman
    ];
  };

  # Required as we are not running XFCE
  # For Thunar-specific settings (list view, hidden files, etc.)
  programs.xfconf.enable = true;

  # Required as we are not running XFCE
  # For general GTK settings and file dialogs
  programs.dconf.enable = true;

  services.gvfs.enable = true;    # Mount, trash, and other functionalities
  services.udisks2.enable = true; # The Hardware Backend (Mounting/Ejecting)
  services.tumbler.enable = true; # Thumbnail support for images
}

