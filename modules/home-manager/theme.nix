# Note: Sway requires this in its configuration file:
# seat seat0 xcursor_theme Adwaita 24
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.cytopia.ui.theme;

in {
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.ui.theme = {
    enable = mkEnableOption "Enable custom GTK/QT/Cursor styling";

    font = {
      name = mkOption { type = types.str; default = "Adwaita Sans"; };
      size = mkOption { type = types.int; default = 11; };
      package = mkOption { type = types.package; default = pkgs.adwaita-fonts; };
    };

    cursor = {
      name = mkOption { type = types.str; default = "Adwaita"; };
      size = mkOption { type = types.int; default = 24; };
      package = mkOption { type = types.package; default = pkgs.adwaita-icon-theme; };
    };

    theme = {
      name = mkOption { type = types.str; default = "Arc"; };
      package = mkOption { type = types.package; default = pkgs.arc-theme; };
    };

    icons = {
      name = mkOption { type = types.str; default = "breeze"; };
      package = mkOption { type = types.package; default = pkgs.libsForQt5.breeze-icons; };
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = mkIf cfg.enable {
    # --- Cursor ---
    home.pointerCursor = {
      inherit (cfg.cursor) name package size;
      gtk.enable = true;
      x11.enable = true;
      sway.enable = true;
    };

    # --- GTK ---
    gtk = {
      enable = true;
      gtk2.enable = true;
      gtk3.enable = true;
      gtk4.enable = true;

      theme = {
        inherit (cfg.theme) name package;
      };

      iconTheme = {
        inherit (cfg.icons) name package;
      };

      font = {
        inherit (cfg.font) name package size;
      };

      # Global Dark Preference
      colorScheme = "dark";
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # --- QT ---
    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };

    # --- Misc Apps ---
    home.sessionVariables = {
      # GTK2 and Motif
      XCURSOR_THEME = cfg.cursor.name;
      XCURSOR_SIZE = toString cfg.cursor.size;

      # Flatpak apps
      GTK_THEME = "Arc-Dark";
      # Java apps
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel";
    };

    # --- Support Packages ---
    home.packages = with pkgs; [
      # Packages used by this module
      cfg.cursor.package
      cfg.theme.package
      cfg.icons.package
      cfg.font.package
      # Core requirements
      pkgs.adwaita-qt       # Required for QT styling
      pkgs.librsvg          # Required for SVG icons
      pkgs.glib             # Required for gsettings

      pkgs.hicolor-icon-theme  # Provides '/usr/share/icons/hicolor/' as a safety net
    ];
  };
}
