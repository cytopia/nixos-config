{ config, lib, ... }:

let
  cfg = config.mySystem.system.locale;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.locale = {
    enable = lib.mkEnableOption "System-wide Locale and Timezone configuration";

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "The system time zone (e.g., 'Europe/Berlin', 'America/New_York').";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "The primary system language. UTF-8 is mandatory for modern systems.";
    };

    # The "Clean" Overwrite Set
    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = { LC_TIME = "de_DE.UTF-8"; LC_MONETARY = "en_GB.UTF-8"; };
      description = "Specific LC_* overrides. Any key not set here defaults to defaultLocale.";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- TIME ---
    time.timeZone = cfg.timeZone;

    # --- INTERNATIONALIZATION ---
    i18n = {
      defaultLocale = cfg.defaultLocale;

      # ARCHITECTURAL LOGIC:
      # We create a base set of all standard LC_ variables pointing to defaultLocale,
      # then merge (//) the user's extraConfig over it.
      extraLocaleSettings = {
        LC_ADDRESS        = cfg.defaultLocale;
        LC_IDENTIFICATION = cfg.defaultLocale;
        LC_MEASUREMENT    = cfg.defaultLocale;
        LC_MONETARY       = cfg.defaultLocale;
        LC_NAME           = cfg.defaultLocale;
        LC_NUMERIC        = cfg.defaultLocale;
        LC_PAPER          = cfg.defaultLocale;
        LC_TELEPHONE      = cfg.defaultLocale;
        LC_TIME           = cfg.defaultLocale;
      } // cfg.extraConfig;
    };
  };
}
