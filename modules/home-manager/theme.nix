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
        # The package ships four directories: "Arc", "Arc-Dark", "Arc-Darker"
        # and "Arc-Lighter". Dark is a separate directory, not a mode: Arc has
        # no gtk-dark.css, so the gtk-application-prefer-dark-theme settings
        # further down are no-ops here. "Arc-Dark" is the only dark selector.
        # "Arc-Darker" is dark chrome with light content areas, not what we
        # want.
        #
        # This used to be "Arc" while GTK_THEME below was hardcoded to
        # "Arc-Dark". That worked, because GTK_THEME overrides gtk-theme-name,
        # but it left the two out of sync. Both now derive from this value.
        default = "Arc-Dark";
      };
      package = mkOption {
        type = types.package;
        # Upstream is the maintained jnsh fork, not the dead horst3180
        # original.
        #
        # Replaces Colloid-Dark-Nord. Nord's palette compresses the whole dark
        # ramp into #2E3440..#4C566A, and Colloid draws a selected row as a
        # low-alpha accent overlay, so selected and unselected rows landed
        # within a few percent luminance of each other. That is unreadable in
        # the Thunderbird message list and calendar. Arc-Dark paints selection
        # as solid #5294E2 on #383C4A instead.
        #
        # Note this build has no GTK2 assets (upstream dropped gtk2), so GTK2
        # apps fall back to the stock GTK2 theme.
        default = pkgs.arc-theme;
      };
    };

    icons = {
      name = mkOption {
        type = types.str;
        # "breeze-dark" gives light-stroked monochrome icons, which is the
        # variant intended for a dark theme. Same package ships both.
        default = "breeze-dark";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.kdePackages.breeze-icons;
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = mkIf cfg.enable {
    # --- Cursor ---
    home.pointerCursor = {
      enable = true;
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
      gtk4.theme ={
        inherit (cfg.theme) name package;
      };

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
      platformTheme.name = "gtk3";
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
        GTK_THEME = cfg.theme.name;
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
      numix-icon-theme
      #papirus-icon-theme
    ];
  };
}
