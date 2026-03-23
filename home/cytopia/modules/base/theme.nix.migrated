{ config, pkgs, ... }:

{

  ###
  ### Cursor
  ###
  # Note: Add this line to Sway config
  # seat seat0 xcursor_theme Adwaita 24
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true; # Helps with older XWayland apps
    sway.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Environment variables for Wayland/Sway.
  # Some apps (and XWayland apps) check these instead of dconf.
  # TODO: check if this is needed
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  ###
  ### GTK
  ###
  gtk = {
    enable = true;
    gtk2.enable = true;
    gtk3.enable = true;
    gtk4.enable = true;

    theme = {
      name = "Arc";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      name = "breeze";
      package = pkgs.libsForQt5.breeze-icons;
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
      package = pkgs.adwaita-fonts;
    };
    # Use dark theme
    colorScheme = "dark";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  ###
  ### QT
  ###
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };

  ###
  ### Extra packages
  ###
  home.packages = with pkgs; [
    # --- Fonts ---
    adwaita-fonts

    # --- Themes ---
    catppuccin
    catppuccin-gtk
    catppuccin-cursors
    catppuccin-papirus-folders

    numix-gtk-theme
    numix-icon-theme
    numix-cursor-theme

    arc-theme
    arc-icon-theme

    adwaita-qt          # helps QT apps mimic the Adwaita/GTK look better
    adwaita-icon-theme  # The standard fallback
    hicolor-icon-theme  # The mandatory base theme

    # --- System Tools ---
    librsvg # This provides the SVG loader for gdk-pixbuf
    gtk4-layer-shell

    glib  # provides gsettings command
  ];
}

