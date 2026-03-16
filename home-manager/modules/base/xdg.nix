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
    #extraConfig = {
    #  XDG_PROJECTS_DIR = "${home}/Projects";
    #  XDG_WORK_DIR = "${home}/Work";
    #};
  };

  xdg.mime = {
	enable = true;
  };

  xdg.mimeApps = {
	enable = true;

    # Default applications
    defaultApplications = {
      "image/*" = [
        "swayimg.desktop"
        "gimp.desktop"
      ];
    };
    # Additional application associations
    #addedAssociations = {
    #};
  };
}


