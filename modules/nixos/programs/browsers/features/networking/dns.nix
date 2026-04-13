{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.networking.dns;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.networking.dns = {

            enableBuiltInDns = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enables Chromium's internal asynchronous DNS client.";
            };

            disableInterceptionChecks = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables Chrome's "DNS Interception" detection probes.
                This is REQUIRED when using a local DNS proxy like dnscrypt-proxy or Pi-hole.
                It prevents the browser from complaining that DNS is being intercepted
                and stops it from trying to bypass your local resolver.
              '';
            };

            enableEncryptedClientHello = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Enables ECH (Encrypted Client Hello).
                Requires DoH to be enabled. Hides the SNI domain name from ISPs.
              '';
            };

            enableAdditionalQueryTypes = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Allows Chromium to query HTTPS/SVCB records directly.";
            };

            # --- DNS OVER HTTPS (DoH) ---
            doh = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable DNS-over-HTTPS (DoH).";
              };

              mode = lib.mkOption {
                type = lib.types.enum [
                  "off"
                  "automatic"
                  "secure"
                ];
                default = "secure";
                description = ''
                  "secure": Strictly forces DoH. Fails if the DoH server is unreachable.
                  "automatic": Falls back to plaintext DNS if DoH fails.
                '';
              };

              template = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = ''
                  The URI template for the DoH resolver.
                  E.g.: "https://127.0.0.1:3000/dns-query"
                '';
              };

              excludedDomains = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "*.local"
                  "*.internal"
                ];
                description = "Bypass DoH for internal domains. Routes to systemd-resolved (plaintext).";
              };
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              {
                "BuiltInDnsClientEnabled" = cfg.enableBuiltInDns;
                "AdditionalDnsQueryTypesEnabled" = cfg.enableAdditionalQueryTypes;
                "EncryptedClientHelloEnabled" = cfg.enableEncryptedClientHello;
              }

              (lib.mkIf cfg.disableInterceptionChecks {
                # This stops Chrome from sending "random" domain pings to detect if the
                # network is hijacking DNS. When using dnscrypt-proxy, this hijacking
                # is intentional and desired.
                "DNSInterceptionChecksEnabled" = false;
              })

              (lib.mkIf cfg.doh.enable {
                "DnsOverHttpsMode" = cfg.doh.mode;
                "DnsOverHttpsTemplates" = cfg.doh.template;
                "DnsOverHttpsExcludedDomains" = cfg.doh.excludedDomains;
              })

              (lib.mkIf (!cfg.doh.enable) {
                "DnsOverHttpsMode" = "off";
              })
            ];
          };
        }
      )
    );
  };
}
