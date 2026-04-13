{
  config,
  lib,
  pkgs-unstable,
  ...
}:

let
  cfg = config.mySystem.programs._1password;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs._1password = {
    enable = lib.mkEnableOption "1Password Gui";

    username = lib.mkOption {
      type = lib.types.str;
      description = ''
        The username is required for certain features (including cli integration) to work with polkit.
      '';
    };

  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ cfg.username ];
      package = pkgs-unstable._1password-gui;
    };
  };
}
