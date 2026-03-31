{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.system.keyboard;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.keyboard = {
    enable = lib.mkEnableOption "Generic/Headless keyboard configuration";

    # TTY Keymap (e.g., 'us', 'de-latin1', 'uk')
    # Note: These are different from XKB names. See 'localectl list-keymaps'
    ttyKeymap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "The keymap for the virtual console (TTY).";
    };

    # Repeat Rate Settings (Physical Console)
    repeatDelay = lib.mkOption {
      type = lib.types.str;
      default = "250";
      description = "Delay before a key starts repeating (in ms).";
    };

    repeatRate = lib.mkOption {
      type = lib.types.str;
      default = "50.0";
      description = "How many times a key repeats per second.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # THE VIRTUAL CONSOLE (Headless/TTY) ---
    console = {
      keyMap = lib.mkDefault cfg.ttyKeymap;
      # You can also set a specific font for better readability on servers
      # font = "Lat2-Terminus16";
    };

    # HARDWARE REPEAT RATE (Headless/Generic) ---
    # Since we aren't using X11's 'autoRepeat' options, we use 'kbdrate'.
    # This systemd service applies the repeat rate to the kernel virtual console.
    systemd.services.set-kbdrate = {
      description = "Set the physical keyboard repeat rate and delay";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardInput = "tty";
        StandardOutput = "journal";
        StandardError = "journal"; # Captures errors (like 'keyboard not found')
        # Path to kbdrate binary from the kbd package
        ExecStart = "${pkgs.kbd}/bin/kbdrate -d ${cfg.repeatDelay} -r ${cfg.repeatRate}";
      };
    };
  };
}
