# Note: Sway requires this in its configuration file:
# seat seat0 xcursor_theme Adwaita 24
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.cytopia.ui.theme;

  # Scaling:
  # XWayland (Legacy X11/GTK/Qt): Scaled via xresources.
  # Native GTK (Wayland): Scaled via dconf.
  # Native Qt (Wayland): Scaled via QT_WAYLAND_FORCE_DPI.
  # Cursors: Handled natively and via environment variables.
  scaling = {
    factor = cfg.scalingFactor;
    dpi = builtins.floor (cfg.scalingFactor * 96.0);
    cursor = builtins.floor (cfg.scalingFactor * (cfg.cursor.size * 1.0));
  };
in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.ui.theme = {
    enable = mkEnableOption "Enable custom GTK/QT/Cursor styling";

    scalingFactor = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = ''
        The ui scaling factor.
        Leave at 1.0 for native scaling. Use 1.5 for 150%, etc.
      '';
    };

    font = {
      name = mkOption {
        type = types.str;
        default = "Adwaita Sans";
      };
      size = mkOption {
        type = types.int;
        default = 11;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.adwaita-fonts;
      };
    };

    cursor = {
      name = mkOption {
        type = types.str;
        default = "Adwaita";
      };
      size = mkOption {
        type = types.int;
        default = 24;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.adwaita-icon-theme;
      };
    };

    theme = {
      name = mkOption {
        type = types.str;
        default = "Arc";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.arc-theme;
      };
    };

    icons = {
      name = mkOption {
        type = types.str;
        default = "breeze";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.libsForQt5.breeze-icons;
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = mkIf cfg.enable {
    # --- Cursor ---
    home.pointerCursor = {
      inherit (cfg.cursor) name package;
      size = if (cfg.scalingFactor != 1.0) then scaling.cursor else cfg.cursor.size;
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

    # Scaling
    dconf.settings = lib.optionalAttrs (cfg.scalingFactor != 1.0) {
      "org/gnome/desktop/interface" = {
        text-scaling-factor = lib.hm.gvariant.mkDouble scaling.factor; # Enforce strict GVariant double type to prevent trailing zero strings
        cursor-size = scaling.cursor;
      };
    };

    xresources.properties = lib.optionalAttrs (cfg.scalingFactor != 1.0) {
      "Xft.dpi" = scaling.dpi;
    };

    # --- Misc Apps ---
    home.sessionVariables =
      # Only added if scalingFactor is not 1.0
      lib.optionalAttrs (cfg.scalingFactor != 1.0) {
        QT_WAYLAND_FORCE_DPI = toString scaling.dpi;
        #GDK_DPI_SCALE = toString cfg.scalingFactor;
        #QT_SCALE_FACTOR = toString cfg.scalingFactor;
      }
      // {
        # GTK2 and Motif
        XCURSOR_SIZE =
          if (cfg.scalingFactor != 1.0) then toString scaling.cursor else toString cfg.cursor.size;
        XCURSOR_THEME = cfg.cursor.name;

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
      adwaita-qt # Required for QT styling
      librsvg # Required for SVG icons
      glib # Required for gsettings
      # Icon themes
      hicolor-icon-theme # Provides '/usr/share/icons/hicolor/' as a safety net
      pop-icon-theme
      arc-icon-theme
      numix-icon-theme
      #papirus-icon-theme
    ];
  };
}
