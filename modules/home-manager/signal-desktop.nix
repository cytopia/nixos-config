{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.cytopia.gui.signal-desktop;

in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.gui.signal-desktop = {
    enable = mkEnableOption "Install Signal Desktop";

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

    home.packages = with pkgs; [
      signal-desktop
    ];

    nixpkgs.overlays = [
      (
        final: prev:
        let
          commandLineArgs = lib.optionals (cfg.scalingFactor != 1.0) [
            "--force-device-scale-factor=${builtins.toJSON cfg.scalingFactor}"
          ];
        in
        {
          # Rewrite the google-chrome package system-wide
          signal-desktop = prev.signal-desktop.override {
            commandLineArgs = commandLineArgs;
          };
        }
      )
    ];
  };
}
