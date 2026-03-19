{ config, pkgs, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "${config.home.homeDirectory}/Desktop";
    download = "${config.home.homeDirectory}/Downloads";
    documents = "${config.home.homeDirectory}/Documents";
    pictures = "${config.home.homeDirectory}/Pictures";
    music = null;
    publicShare = null;
    templates = null;
    videos = "${config.home.homeDirectory}/Videos";
    extraConfig = {
      XDG_PROJECTS_DIR = "${config.home.homeDirectory}/repo";
      #XDG_WORK_DIR = "${config.home.homeDirectory}/Work";
    };
  };

  xdg.mime = {
	enable = true;
  };

  # NOTE: If enabled, generated config $XDG_CONFIG_HOME/mimeapps.list will be read-only.
  xdg.mimeApps = {
	enable = true;

    # Default applications
    defaultApplications = {
      "image/png" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/jpeg" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/gif" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/webp" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/svg" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/raw" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/tiff" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/heif" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
      "image/bmp" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
    };
  };
}


