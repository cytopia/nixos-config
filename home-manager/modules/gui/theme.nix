{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk2.enable = true;
    gtk3.enable = true;
    gtk4.enable = true;

    theme = {
      name = "catppuccin-frappe-blue-standard";
      #package = "";
    };
    iconTheme = {
      name = "breeze-dark";
      #package = "";
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
      #package = "";
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
      #package = "";
    };
    colorScheme = "dark";  # or light

  };

  home.packages = with pkgs; [
    catppuccin
    catppuccin-gtk
    catppuccin-cursors
    catppuccin-papirus-folders
    #papirus-icon-theme
  ];
}

