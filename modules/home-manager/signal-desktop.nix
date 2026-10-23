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

    # signal-desktop's `commandLineArgs` override arg was removed (now a hard
    # throw) in nixpkgs PR #570229. To pass --force-device-scale-factor we wrap
    # the binary with symlinkJoin + wrapProgram instead. The upstream
    # signal.desktop launcher uses `Exec=signal-desktop %U` (bare name resolved
    # via PATH), so both the app launcher and the CLI get the flag, while the
    # upstream .desktop / icon / MIME handlers stay untouched.
    home.packages = [
      (
        if cfg.scalingFactor == 1.0 then
          pkgs.signal-desktop
        else
          pkgs.symlinkJoin {
            name = "signal-desktop-scaled";
            paths = [ pkgs.signal-desktop ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/signal-desktop \
                --add-flags "--force-device-scale-factor=${builtins.toJSON cfg.scalingFactor}"
            '';
            meta.mainProgram = "signal-desktop";
          }
      )
    ];
  };
}
