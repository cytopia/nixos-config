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
    # Stop captive portal checks (e.g., hotel Wi-Fi login detection)
    "network.captive-portal-service.enabled" = false;
    # Disable Safe Browsing to ensure zero background noise connecting to Google APIs
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;

    # Enforce Strict Cryptography (ECH & HTTPS-Only)
    "dom.security.https_only_mode" = true;
    "network.dns.echconfig.enabled" = true;
    "network.dns.echconfig.fallback_to_origin_when_all_failed" = false;
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
