{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.cytopia.service.dns;
  dohCfg = cfg.localDoh;
in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  options.cytopia.service.dns.localDoh = {
    enable = lib.mkEnableOption "Local DoH listener for browsers (ECH support)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "The port on which the local DoH server will listen (e.g., 3000).";
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "/dns-query";
      description = "The path on which the local DoH server will serve.";
    };

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also listen on IPv6";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf (cfg.enable && dohCfg.enable) {

    assertions = [
      {
        assertion = lib.hasPrefix "/" dohCfg.path;
        message = ''
          [DNS Module Error]: 'localDoh.path' MUST start with a forward slash '/'.
          Current value is: ${dohCfg.path}
        '';
      }
      {
        assertion = options.cytopia.service.dns ? certs;
        message = ''
          [DNS Module Error]: 'localDoh' requires 'feature-certs.nix' to be imported in the module 'imports' list.
        '';
      }
    ];

    # Open the local DoH listener in dnscrypt-proxy
    services.dnscrypt-proxy.settings = {
      local_doh = {
        listen_addresses = [
          "127.0.0.1:${toString dohCfg.port}"
        ]
        ++ lib.optionals dohCfg.ipv6 [ "[::1]:${toString dohCfg.port}" ];

        path = dohCfg.path;

        # We can hardcode these because feature-certs.nix guarantees
        # they will be generated and placed here before the service starts!
        cert_file = "/var/lib/dnscrypt-proxy/certs/localhost.pem";
        cert_key_file = "/var/lib/dnscrypt-proxy/certs/localhost-key.pem";
      };
    };
  };
}
