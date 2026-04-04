{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.utils.camera-toggle;

  # Nix will interpolate this to the exact /nix/store/.../bin/modprobe path
  modprobePath = "${pkgs.kmod}/bin/modprobe";

  # Create a unified script to handle the toggling
  cameraToggleScript = pkgs.writeShellScriptBin "custom-camera-toggle" ''
    # Choose your preferred icons here
    ICON_ON="󰄀"
    ICON_OFF="󰄀"

    # Helper function to check if the module is loaded
    is_loaded() {
      [ -d /sys/module/uvcvideo ]
    }

    if [ -z "$1" ]; then
      # No arguments: Output JSON for i3status-rust
      if is_loaded; then
        echo '{"text": "'"$ICON_ON"' ON", "state": "Warning"}'
      else
        echo '{"text": "'"$ICON_OFF"' OFF", "state": "Idle"}'
      fi

    elif [ "$1" = "toggle" ]; then
      # Toggle state silently (i3status-rust handles the UI updates)
      if is_loaded; then
        systemctl --user stop wireplumber
        sudo ${modprobePath} -r uvcvideo
        systemctl --user start wireplumber
      else
        sudo ${modprobePath} uvcvideo
      fi

    else
      echo "Usage: camera-toggle [toggle]"
    fi
  '';
in
{

  ###
  ### 1. OPTIONS
  ###
  options.mySystem.utils.camera-toggle = {
    enable = lib.mkEnableOption "System user management";

    userName = lib.mkOption {
      type = lib.types.str;
      description = ''
        The username of the primary system user.
        This user will granted modprobe [r] permissions on uvcvideo kernel module
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Add the script to your system packages
    environment.systemPackages = [
      cameraToggleScript
    ];

    # Define the exact sudo rules securely for user 'cytopia'
    security.sudo.extraRules = [
      {
        users = [ cfg.userName ];
        commands = [
          {
            command = "${modprobePath} uvcvideo";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${modprobePath} -r uvcvideo";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
