{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.cytopia.gui.slack;

  # If scaling is 1.0, just use the normal package.
  # Otherwise, create a lightweight wrapper around it.
  custom-slack =
    if cfg.scalingFactor == 1.0 then
      pkgs.slack
    else
      pkgs.symlinkJoin {
        name = "slack-scaled";
        paths = [ pkgs.slack ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          # 1. Wrap the executable
          wrapProgram $out/bin/slack \
            --add-flags "--force-device-scale-factor=${builtins.toJSON cfg.scalingFactor}"

          # 2. Fix the .desktop file for GUI launchers like Fuzzel
          # Remove the read-only symlink
          rm $out/share/applications/slack.desktop

          # Copy the original file so we can modify it
          cp ${pkgs.slack}/share/applications/slack.desktop $out/share/applications/slack.desktop

          # Make the copied file writable
          chmod +w $out/share/applications/slack.desktop

          # Use sed to replace the Exec line with the absolute path to our new wrapper
          sed -i "s|^Exec=.*|Exec=$out/bin/slack %U|" $out/share/applications/slack.desktop
        '';
      };

in
{
  ###
  ### 1. OPTIONS
  ###
  options.cytopia.gui.slack = {
    enable = mkEnableOption "Install Slack";

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
      custom-slack
    ];
  };
}
