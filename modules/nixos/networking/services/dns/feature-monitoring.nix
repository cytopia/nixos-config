{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.cytopia.service.dns;
  monCfg = cfg.localMonitoring;
in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  options.cytopia.service.dns.localMonitoring = {
    enable = lib.mkEnableOption "Local Monitoring Dashboard";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4400;
      description = "Bind port for local web interface";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for web interface.";
    };

    pass = lib.mkOption {
      type = lib.types.str;
      default = "nixos-stats";
      description = "Password for web interface.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf (cfg.enable && monCfg.enable) {

    assertions = [
      {
        assertion = options.cytopia.service.dns ? certs;
        message = ''
          [DNS Module Error]: 'localMonitoring' requires 'feature-certs.nix' to be imported in the module 'imports' list.
        '';
      }
    ];

    services.dnscrypt-proxy.settings = {

      monitoring_ui = {
        enabled = true;
        # We use 4400 to avoid common port conflicts with web development (8080)
        listen_address = "127.0.0.1:${toString monCfg.port}";

        # Since it's local only, a simple username/password is fine
        username = monCfg.user;
        password = monCfg.pass;

        # REUSE SHARED CERTS
        # These are guaranteed to exist because feature-certs.nix generates them
        # whenever this module is enabled!
        tls_certificate = "/var/lib/dnscrypt-proxy/certs/localhost.pem";
        tls_key = "/var/lib/dnscrypt-proxy/certs/localhost-key.pem";

        # INSIGHT SETTINGS
        enable_query_log = true; # Required to see the live scrolling list
        max_query_log_entries = 300; # Default is 100

        # Privacy Levels:
        # 0 = Show everything (Best for debugging your Chrome/System flow)
        # 1 = Hide client IPs (Safe default)
        # 2 = Hide everything but basic stats
        privacy_level = 0;
      };
    };
  };
}
