{ config, pkgs, ... }:

{
  # 1. DCONF: Essential for GTK4/Libadwaita apps
  #dconf.settings = {
  #  "org/gnome/desktop/interface" = {
  #    cursor-theme = "Adwaita";
  #    cursor-size = 24;
  #    color-scheme = "prefer-dark";
  #    # These ensure GTK4 apps use your chosen icons and fonts
  #    icon-theme = "breeze";
  #    font-name = "Adwaita Sans 11";
  #    gtk-theme = "Arc";
  #  };
  #};

  # 2. POINTER CURSOR: The "modern" way to handle cursors in HM
  # This replaces manual sessionVariables and cursorTheme entries
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
    #cursorTheme = {
    #  name = "Adwaita";
    #  size = 24;
    #  package = pkgs.adwaita-icon-theme;
    #  # Note: Ad this line to Sway config
    #  # seat seat0 xcursor_theme Adwaita 24
    #};
    font = {
      name = "Adwaita Sans";
      size = 11;
      package = pkgs.adwaita-fonts;
    };
    colorScheme = "dark";  # or light
    # Modern apps look for this key in dconf via the portal
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt = {
    enable = true;
    #platformTheme.name = "gtk";
    # In 2026, 'xdgdesktopportal' is the preferred bridge over 'gtk'
    # because it respects the system-wide Dark Mode toggle better.
    platformTheme.name = "xdgdesktopportal";
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

