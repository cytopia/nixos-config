{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.system.fonts;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.fonts = {
    enable = lib.mkEnableOption "System-wide fonts";

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

    fonts.enableDefaultPackages = cfg.enableDefaultPackages;

    # NixOS 25.11 uses 'fonts.packages'.
    # (Older versions used 'fonts.fonts')
    fonts.packages = with pkgs; [
      # Standard high-quality UI fonts
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-emoji-blob-bin

      # Terminal/TTY specialty fonts
      terminus_font
      terminus_font_ttf

      # Nerd Fonts (Selective collection for speed)
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.terminess-ttf
      nerd-fonts.ubuntu
      nerd-fonts.symbols-only # Great fallback for any font
    ];

    # This is the "Magic" block for Fontconfig
    fonts.fontconfig = {
      enable = true;
      antialias = true;

      # Optimized for Laptop LCDs
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";

      hinting = {
        enable = true;
        style = "slight"; # Best for modern high-res laptop screens
      };

      # ARCHITECTURAL HIERARCHY: [ Preferred -> Unicode Fallback -> Legacy Fallback ]
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Inter"
          "Noto Sans"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif"
          "DejaVu Serif"
        ];
        emoji = [
          "Noto Color Emoji"
          "DejaVu Sans" # DejaVu actually has some basic emoji symbols
        ];
      };
    };
  };
}
