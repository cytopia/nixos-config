{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk2.enable = true;
    gtk3.enable = true;
    gtk4.enable = true;

    theme = {
      name = "Arc";
      #name = "catppuccin-frappe-blue-standard";
      #package = "";
    };
    iconTheme = {
      #name = "Papirus-Dark";
      name = "breeze";
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
    #papirus-icon-theme
    catppuccin-papirus-folders # Icon theme, e.g. for Thunar

    numix-gtk-theme
    numix-icon-theme
    numix-cursor-theme

    arc-theme
    arc-icon-theme

    adwaita-icon-theme  # The standard fallback
    hicolor-icon-theme  # The mandatory base theme
    #papirus-icon-theme  # A high-coverage theme for testing

    librsvg # This provides the SVG loader for gdk-pixbuf

    gtk4-layer-shell
  ];
}

