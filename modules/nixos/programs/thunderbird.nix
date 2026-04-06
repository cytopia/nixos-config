{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.programs.thunderbird;

  # https://firefox-source-docs.mozilla.org/networking/dns/dns-over-https-trr.html
  dohPolicies = {
    Certificates.Install = [ cfg.dnsOverHttps.caCertPath ];
  };
  dohPreferences = {
    # Strict DoH (Pointing to your local DNSCrypt)
    "network.trr.mode" = 3;
    "network.trr.uri" = cfg.dnsOverHttps.url;
    "network.trr.custom_uri" = cfg.dnsOverHttps.url;
    "network.trr.fallback-on-zero-response" = false;
    "network.trr.wait-for-confirmation" = false;
    "network.dns.use_https_rr_as_altsvc" = true;
    "network.dns.echconfig.enabled" = true;
    "network.dns.http3_echconfig.enabled" = true;
    "network.dns.native_https_query" = true;
    "network.dns.echconfig.fallback_to_origin_when_all_failed" = false;
  };

  securityPreferences = {
    # Proxy & DNS Resolution (Force through DNSCrypt, prevent SOCKS leaks)
    "network.proxy.socks_remote_dns" = false;
    "network.proxy.socks5_remote_dns" = false;

    # Disable all Prefetching & Speculative Connections
    "network.dns.disablePrefetch" = true;
    "network.dns.disablePrefetchFromHTTPS" = true;
    "network.prefetch-next" = false;
    "network.predictor.enabled" = false;
    "dom.prefetch_dns_for_anchor_http_document" = false;
    "dom.prefetch_dns_for_anchor_https_document" = false;

    # Stop Phoning Home (Connectivity Checks, Telemetry, Geolocation)
    "network.connectivity-service.enabled" = false;
    "geo.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "network.captive-portal-service.enabled" = false;
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;

    # ADD: Advanced Telemetry & FOG (Glean) Hardening
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.dap_enabled" = false;
    "telemetry.fog.test.localhost_port" = 0;

    # Enforce Strict Cryptography (HTTPS-Only)
    "dom.security.https_only_mode" = true;
  };

in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird system settings";

    dnsOverHttps = {
      enable = lib.mkEnableOption "Enable DNS over HTTPS";

      url = lib.mkOption {
        type = lib.types.str;
        description = "The URL of the DNS over HTTPS server.";
      };
      caCertPath = lib.mkOption {
        type = lib.types.str;
        description = "The absolute path of CA certificate to import required by the DoH servers.";
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable (
    lib.mkMerge [

      # Base Thunderbird Configuration
      {
        programs.thunderbird = {
          enable = true;
          policies = {
            DisableAppUpdate = true;
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
          };
          preferences = { };
        };
      }

      # Security Preferences
      {
        programs.thunderbird = {
          preferences = securityPreferences;
        };
      }

      # Conditional DoH Configuration
      (lib.mkIf cfg.dnsOverHttps.enable {
        programs.thunderbird = {
          policies = dohPolicies;
          preferences = dohPreferences;
        };
      })
    ]
  );
}
