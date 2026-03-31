{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

with lib;

let
  cfg = config.cytopia.gui.telegram-desktop;

  # Calculate the scale percentage safely (e.g., 1.3 -> 130 -> "130")
  # The builtins.floor turns the float into an integer, which toString can handle perfectly.
  scalePercent = toString (builtins.floor ((cfg.scalingFactor * 100.0) + 0.5));

  # Define our customized unstable package right here
  custom-telegram = pkgs-unstable.telegram-desktop.overrideAttrs (oldAttrs: {
    preFixup = (oldAttrs.preFixup or "") + ''
      qtWrapperArgs+=(
        --set QT_SCALE_FACTOR "1"
        ${optionalString (cfg.scalingFactor != 1.0) ''--add-flags "-scale ${scalePercent}"''}
      )
    '';
  });

in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.gui.telegram-desktop = {
    enable = mkEnableOption "Install Telegram Desktop";

    scalingFactor = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = ''
        The ui scaling factor.
        Leave at 1.0 for native scaling. Use 1.5 for 150%, etc.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    home.packages = [
      custom-telegram
    ];
  };
}
