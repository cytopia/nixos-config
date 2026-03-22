{ config, pkgs, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-theme = "Adwaita";
      cursor-size = 24;
      color-scheme = "prefer-dark";
      # These ensure GTK4 apps use your chosen icons and fonts
      icon-theme = "breeze";
      font-name = "Adwaita Sans 11";
      gtk-theme = "Arc";
    };
  };

  # ADDED: Environment variables for Wayland/Sway.
  # Some apps (and XWayland apps) check these instead of dconf.
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };


  gtk = {
    enable = true;
    gtk2.enable = true;
    gtk3.enable = true;
    gtk4.enable = true;

    theme = {
      #name = "catppuccin-frappe-blue-standard";
      name = "Arc";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      #name = "Papirus-Dark";
      name = "breeze";
      package = pkgs.libsForQt5.breeze-icons;
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
      package = pkgs.adwaita-icon-theme;
      # Note: Ad this line to Sway config
      # seat seat0 xcursor_theme Adwaita 24
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
      package = pkgs.adwaita-fonts;
    };
    colorScheme = "dark";  # or light
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  home.packages = with pkgs; [
    # --- Fonts ---
    adwaita-fonts

    # --- Themes ---
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

    adwaita-qt          # helps QT apps mimic the Adwaita/GTK look better
    adwaita-icon-theme  # The standard fallback
    hicolor-icon-theme  # The mandatory base theme
    #papirus-icon-theme  # A high-coverage theme for testing

    # --- System Tools ---
    librsvg # This provides the SVG loader for gdk-pixbuf
    gtk4-layer-shell

    glib  # provides gsettings command
  ];
}

