{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cytopia.cli.devbox;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.cli.devbox = {
    enable = lib.mkEnableOption "Jetify devbox";

    # External helper programms
    enableDirenv = lib.mkEnableOption "Direnv integration";
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Install required packages
    home.packages = [
      pkgs.devbox
    ];

    home.sessionVariables = {
      # Disable devbox telemetry:
      # https://github.com/jetify-com/devbox/blob/main/internal/envir/util.go#L24
      DO_NOT_TRACK = "1";
    };

    programs.direnv = lib.mkIf cfg.enableDirenv {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
