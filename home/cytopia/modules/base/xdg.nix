{ config, ... }:

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
    };
  };
  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Desktop Desktop"
    "file://${config.home.homeDirectory}/repo repo"
  ];

  xdg.mime = {
    enable = true;
  };
}
