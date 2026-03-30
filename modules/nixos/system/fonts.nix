{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.system.fonts;

  # Test if the names are correct via:
  #   fc-list "JetBrainsMono Nerd Font Mono" family
  #
  # And to list all installed fonts:
  #   fc-list : family | cut -d, -f1 | sort -u
  #
  # Query for system default monospace
  #   fc-match -s monospace
  # Query for system default Sans-Serif
  #   fc-match -s sans-serif
  # Query for system default Serif
  #   fc-match -s serif
  # Query for system default Emoji
  #   fc-match -s emoji
  fontChoices = {

    # The "Bulletproof" look: Maximum character coverage for global compatibility.
    noto = {
      monospace = [
        "Noto Sans Mono"
        "Symbols Nerd Font Mono"
        "Noto Sans CJK JP"
      ];
      sanSerif = [
        "Noto Sans"
        "Noto Sans CJK JP"
      ];
      serif = [
        "Noto Serif"
        "Noto Serif CJK JP"
      ];
      emoji = [ "Noto Color Emoji" ];
      packages = [
        pkgs.noto-fonts
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        pkgs.noto-fonts-color-emoji
      ];
    };

    # The "Senior Dev" look: High x-height for coding comfort.
    # Paired with Inter for UI as they share modern geometric DNA.
    jetbrains = {
      monospace = [
        "JetBrains Mono"
        "Symbols Nerd Font Mono"
        "Noto Sans CJK JP"
      ];
      sanSerif = [
        "Inter"
        "Noto Sans CJK JP"
      ];
      serif = [
        "Source Serif 4"
        "Noto Serif CJK JP"
      ];
      emoji = [ "Noto Color Emoji" ];
      packages = [
        pkgs.jetbrains-mono
        pkgs.inter
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        pkgs.source-serif
        pkgs.noto-fonts-color-emoji
      ];
    };

    # The "Functional" look: Heavy use of programming ligatures.
    firaCode = {
      monospace = [
        "Fira Code"
        "Symbols Nerd Font Mono"
        "Noto Sans CJK JP"
      ];
      sanSerif = [
        "Fira Sans"
        "Noto Sans CJK JP"
      ];
      serif = [
        "Noto Serif"
        "Noto Serif CJK JP"
      ];
      emoji = [ "Noto Color Emoji" ];
      packages = [
        pkgs.fira-code
        pkgs.fira
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        pkgs.noto-fonts-color-emoji
      ];
    };

    # The "Hacker" look: Retro, pixel-perfect sharpness.
    # Recommended only for 1.0x or 2.0x integer scaling on Wayland.
    terminess = {
      monospace = [
        "Terminess Nerd Font"
        "Symbols Nerd Font Mono"
        "Noto Sans CJK JP"
      ];
      sanSerif = [
        "Inter"
        "Noto Sans CJK JP"
      ];
      serif = [
        "Source Serif 4"
        "Noto Serif CJK JP"
      ];
      emoji = [ "Noto Color Emoji" ];
      packages = [
        pkgs.nerd-fonts.terminess-ttf
        pkgs.inter
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        pkgs.source-serif
        pkgs.noto-fonts-color-emoji
      ];
    };
  };
  selectedFont = fontChoices."${cfg.fontChoice}";
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.fonts = {
    enable = lib.mkEnableOption "System-wide fonts";

    fontChoice = lib.mkOption {
      type = lib.types.enum (builtins.attrNames fontChoices);
      default = "jetbrains";
      description = "Select the primary font stack to use across the system.";
    };

    enableDefaultPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable a basic set of fonts providing several styles and families and reasonable coverage of Unicode.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Enable a basic set of fonts providing several styles and families and
    # reasonable coverage of Unicode.
    fonts.enableDefaultPackages = cfg.enableDefaultPackages;

    # Whether to add the fonts provided by Ghostscript (such as various URW fonts
    # and the “Base-14” Postscript fonts) to the list of system fonts, making
    # them available to X11 applications.
    fonts.enableGhostscriptFonts = true;

    # Whether to create a directory with links to all fonts in
    # /run/current-system/sw/share/X11/fonts.
    fonts.fontDir.enable = true;

    # Ensure chosen set of Fonts will be installed
    fonts.packages = selectedFont.packages;

    # This is the "Magic" block for Fontconfig
    fonts.fontconfig = {
      # If enabled, a Fontconfig configuration file will be built pointing to a
      # set of default fonts. If you don't care about running X11 applications or
      # any other program that uses Fontconfig, you can turn this option off an
      # prevent a dependency on all those fonts.
      enable = true;

      # At high resolution (> 200 DPI), antialiasing has no visible effect;
      # users of such displays may want to disable this option.
      antialias = true;

      subpixel = {
        # Optimized for Laptop LCDs
        # "rgb", "bgr", "vrgb", "vbgr", "none"
        rgba = "rgb";
        # FreeType LCD filter. At high resolution (> 200 DPI), LCD filtering has
        # no visible effect; users of such displays may want to select none.
        lcdfilter = "default";
      };

      hinting = {
        # Hinting aligns glyphs to pixel boundaries to improve rendering sharpness
        # at low resolution. At high resolution (> 200 dpi) hinting will do nothing
        # (at best); users of such displays may want to disable this option.
        enable = true;
        # slight will make the font more fuzzy to line up to the grid but will be
        # better in retaining font shape, while full will be a crisp font that
        # aligns well to the pixel grid but will lose a greater amount of font shape.
        # "none", "slight", "medium", "full"
        style = "slight";
      };

      # ARCHITECTURAL HIERARCHY: [ Preferred -> Unicode Fallback -> Legacy Fallback ]
      defaultFonts = {
        monospace = selectedFont.monospace;
        sansSerif = selectedFont.sanSerif;
        serif = selectedFont.serif;
        emoji = selectedFont.emoji;
      };
    };
  };
}
