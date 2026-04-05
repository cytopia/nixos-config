# ===========================================================================
# DNS TRAFFIC FLOW OVERVIEW:
# ===========================================================================
# [Local Apps] (Firefox, curl, ping, etc.)
#      |
#      v  (Queries standard port 53 via standard libc)
# [/etc/resolv.conf] (Hardcoded stub listener at 127.0.0.53)
#      |
#      v  (Intercepted by our local routing engine)
# [systemd-resolved] (Cache DISABLED, DNSSEC validation DISABLED)
#      |
#      v  (Forwards exclusively to our custom ports via Domains=~.)
# [127.0.0.1:5353 / [::1]:5353]
#      |
#      v  (Intercepted by the encryption proxy)
# [dnscrypt-proxy] (Cache ENABLED, DNSSEC validation ENABLED)
#      |
#      v  (Encrypted outbound DoH traffic over TCP/443)
# [Quad9 DoH Servers] (9.9.9.9, etc.)
# ===========================================================================

# Config: $(systemctl status dnscrypt-proxy | grep '\-config'| awk '{print $NF}')

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mySystem.networking.service.dns;

  # https://dnscrypt.info/public-servers/
  ###
  ### AvailableDNS server
  ###
  ipv4Servers =
    if cfg.query.protocol == "doh" then
      [
        "quad9-doh-ip4-port443-filter-pri"
        "quad9-doh-ip4-port443-filter-alt"
        "quad9-doh-ip4-port443-filter-alt2"
      ]
    else if cfg.query.protocol == "doh-ecs" then
      [
        "quad9-doh-ip4-port443-filter-ecs-pri"
        "quad9-doh-ip4-port443-filter-ecs-alt"
        "quad9-doh-ip4-port443-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt" then
      [
        "quad9-dnscrypt-ip4-filter-pri"
        "quad9-dnscrypt-ip4-filter-alt"
        "quad9-dnscrypt-ip4-filter-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt-ecs" then
      [
        "quad9-dnscrypt-ip4-filter-ecs-pri"
        "quad9-dnscrypt-ip4-filter-ecs-alt"
        "quad9-dnscrypt-ip4-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "odoh" then
      [ "odoh-cloudflare" ] # Quad9 does not natively support ODoH yet
    else
      [ ];

  ipv6Servers =
    if cfg.query.protocol == "doh" then
      [
        "quad9-doh-ip6-port443-filter-pri"
        "quad9-doh-ip6-port443-filter-alt"
        "quad9-doh-ip6-port443-filter-alt2"
      ]
    else if cfg.query.protocol == "doh-ecs" then
      [
        "quad9-doh-ip6-port443-filter-ecs-pri"
        "quad9-doh-ip6-port443-filter-ecs-alt"
        "quad9-doh-ip6-port443-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt" then
      [
        "quad9-dnscrypt-ip6-filter-pri"
        "quad9-dnscrypt-ip6-filter-alt"
        "quad9-dnscrypt-ip6-filter-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt-ecs" then
      [
        "quad9-dnscrypt-ip6-filter-ecs-pri"
        "quad9-dnscrypt-ip6-filter-ecs-alt"
        "quad9-dnscrypt-ip6-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "odoh" then
      [ ] # TODO: Nothing available
    else
      [ ];

  ###
  ### Available Relays
  ###
  ### https://status.dnscrypt.info/?type=relay
  ipv4Relays = [
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-pri"; via = [ "anon-cs-de" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-alt"; via = [ "anon-cs-berlin" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-alt2"; via = [ "anon-cs-dus" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-pri"; via = [ "dnscry.pt-anon-frankfurt02-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-alt"; via = [ "dnscry.pt-anon-jena-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-alt2"; via = [ "dnscry.pt-anon-bremen-ipv4" ]; }

    { server_name = "quad9-dnscrypt-ip6-filter-ecs-pri"; via = [ "dnscry.pt-anon-dusseldorf-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-ecs-alt"; via = [ "dnscry.pt-anon-dusseldorf02-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-ecs-alt2"; via = [ "dnscry.pt-anon-dusseldorf03-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-pri"; via = [ "dnscry.pt-anon-nuremberg-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-alt"; via = [ "dnscry.pt-anon-munich-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-alt2"; via = [ "anon-cs-de" ]; }

    { server_name = "cs-de"; via = [ "dnscry.pt-anon-frankfurt02-ipv4" ]; }
    { server_name = "ffmuc.net"; via = [ "anon-cs-de" ]; }
    { server_name = "ffmuc.net-v6"; via = [ "anon-cs-de" ]; }
    { server_name = "dnscry.pt-frankfurt02-ipv4"; via = [ "anon-cs-berlin" ]; }
    { server_name = "dnscry.pt-frankfurt02-ipv6"; via = [ "anon-cs-berlin" ]; }
    { server_name = "*"; via = [ "anon-cs-de" ]; }
  ];
  relayedServer = builtins.map (x: x.server_name) ipv4Relays;

  ###
  ### Final DNS Server list
  ###
  # Non-Relay configuration
  activeServerNames = if cfg.query.viaProxy then
    relayedServer
  else
    ipv4Servers ++ (lib.optionals cfg.query.ipv6 ipv6Servers);

  # Relay configuration (TODO: ipv6 is missing)
  activeRelays = ipv4Relays;
in
{
  #################################################################################################
  ###
  ### OPTIONS
  ###
  #################################################################################################
  options.mySystem.networking.service.dns = {
    enable = lib.mkEnableOption "Enable dnscrypt proxy and local resolver";

    query = {
      protocol = lib.mkOption {
        type = lib.types.enum [
          # (DNS over Https) stealthiest protocol
          "doh"
          "doh-ecs" # with subnet forwarding to get faster/closer servers (privacy leak)
          # Security & Speed
          "dnscrypt"
          "dnscrypt-ecs" # with subnet forwarding to get faster/closer servers (privacy leak)
          # Anonymous, but suspicious
          "odoh"
        ];
        default = "doh";
        description = ''
          Chose protocol to fetch DNS records. DoH: most stealth.
        '';
      };
      http3 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Only applies when using DoH.
          Without http3 the DoH traffic looks like normal HTTPS traffic, but is slower.
          With http3 it is using QUIC/UDP and is much faster.
        '';
      };
      ipv6 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable/Disable to query via IPv6.
          It is best to leave this off.
        '';
      };
      viaProxy = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Proxy your encrypted DNS requests through a middle-server so that the DNS server
          does not know your IP address.
        '';
      };
    };
    # Local Blocklist
    localBlockList = {
      # TODO: Remove enable and just do if urls is full
      enable = lib.mkEnableOption "Enable block list";
      urls = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Specify an URL to download a blocklist.
          Examples: https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Public-blocklist
        '';
      };
    };
    whitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "example.com"
        "*.trusted.com"
      ];
      description = ''
        A list of domains to strictly allow, bypassing all blocklists.
        Supports wildcards.
      '';
    };
    # Local DoH server that can be used by browsers (Chrome/FF)
    localDoh = {
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
      caCertPath = lib.mkOption {
        type = lib.types.str; # We use string so Nix doesn't evaluate it as a build-time path
        default = "/run/local-doh-ca/rootCA.pem";
        description = ''
          The full path where the public Root CA will be exposed.
          It MUST be a subdirectory of /run/ (e.g., /run/custom-dir/cert.pem)
          so systemd can automatically create the temporary RuntimeDirectory.
          Use this path to import it into your browser.
        '';
      };
    };
    # Monitoring/Stats Web iterface
    localMonitoring = {
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
  };

  config = lib.mkMerge [

    #################################################################################################
    ###
    ### CONFIGURATION (ENABLED)
    ###
    #################################################################################################

    (lib.mkIf cfg.enable {

      # Ensure mkcert and nss (certutil) are available system-wide for CA management
      environment.systemPackages = lib.mkIf cfg.localDoh.enable [
        pkgs.mkcert
        pkgs.nss
      ];
      networking.firewall.enable = true;
      networking.nftables.enable = true;
      networking.nftables.tables."dns-logging" = {
        # What: A purely passive monitoring table.
        # How: Logs DoH hits and outbound DNS anomalies without altering traffic.
        family = "inet";
        # TODO: if dnscrypt-proxy not uses 53 as its protocl (except bootstrap), then also log it
        content = ''
          # --- KNOWN DNS PROVIDER SETS ---
          # Google DNS (Primary & Secondary)
          set google_dns_v4 { type ipv4_addr; elements = { 8.8.8.8, 8.8.4.4 }; }
          set google_dns_v6 { type ipv6_addr; elements = { 2001:4860:4860::8888, 2001:4860:4860::8844 }; }

          # Cloudflare DNS (Standard, Malware Blocking, and Family)
          set cf_dns_v4 { type ipv4_addr; elements = { 1.1.1.1, 1.0.0.1, 1.1.1.2, 1.0.0.2, 1.1.1.3, 1.0.0.3 }; }
          set cf_dns_v6 { type ipv6_addr; elements = { 2606:4700:4700::1111, 2606:4700:4700::1001, 2606:4700:4700::1112, 2606:4700:4700::1002, 2606:4700:4700::1113, 2606:4700:4700::1003 }; }

          chain input {
            type filter hook input priority -10; policy accept;

            # DISABLED
            # 1. LOG LOCAL DoH HITS (Chrome -> Port 3000)
            #iifname "lo" meta l4proto { tcp, udp } th dport 3000 ct state new log prefix "[DNS-DoH-Local] "
          }

          chain output {
            type filter hook output priority -10; policy accept;

            # 2. LOG ROGUE OUTBOUND DNS
            # Logs any traffic heading out to the internet (not loopback) on DNS ports,
            # explicitly ignoring our dnscrypt-proxy group (gid: 10053).
            oifname != "lo" meta skgid != 10053 meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue] "
            oifname != "lo" meta skgid != 10053 meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT] "

            # --- GOOGLE ---
            ip daddr @google_dns_v4 meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue-Google] "
            ip6 daddr @google_dns_v6 meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue-Google] "

            ip daddr @google_dns_v4 meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT-Google] "
            ip6 daddr @google_dns_v6 meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT-Google] "

            ip daddr @google_dns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-Dnscrypt-Google] "
            ip6 daddr @google_dns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-Dnscrypt-Google] "

            # --- CLOUDFLARE ---
            ip daddr @cf_dns_v4 meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue-Cloudflare] "
            ip6 daddr @cf_dns_v6 meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue-Cloudflare] "

            ip daddr @cf_dns_v4 meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT-Cloudflare] "
            ip6 daddr @cf_dns_v6 meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT-Cloudflare] "

            ip daddr @cf_dns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-Dnscrypt-Cloudflare] "
            ip6 daddr @cf_dns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-Dnscrypt-Cloudflare] "
          }
        '';
      };

      ###
      ### 1. DNSCrypt Proxy
      ###
      # https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
      services.dnscrypt-proxy = {
        enable = lib.mkDefault true;
        settings = lib.mkMerge [
          {
            # ==========================================================
            # PERFORMANCE
            # ==========================================================
            # 0 = Debug, 1 = Info, 2 = Notice (Default), 3 = Warning, 4 = Error
            log_level = 2;

            cache = true;
            # Allocate RAM for 10,000 domains. This ensures that almost every site
            # you visit daily is served instantly from local memory (<1ms).
            # Default: 4096
            cache_size = 10000;
            # It forces even short-lived DNS records to stay in your local cache for 1 hour,
            # bypassing the website owner's settings.
            # This makes the web feel instant and hides your "frequency" from Quad9.
            # Default: 2400
            cache_min_ttl = 3600;
            # Caps the maximum life of a record to 24 hours. This ensures that even
            # stable sites are eventually re-verified for security once a day.
            # Default: 86400
            cache_max_ttl = 86400;
            # Caches "Domain Not Found" (NXDOMAIN) responses. This prevents your browser
            # from spamming the network if you have a typo or an ad-blocker triggers.
            cache_neg_min_ttl = 60;
            cache_neg_max_ttl = 600;

            # Use HTTP/3 (QUIC / UDP) for 0-RTT handshakes upstream, saving ~30ms per query.
            http3 = cfg.query.http3;

            # Do not blindly shoot out HTTP3 (QUIC/UDP) requests.
            # If http3 is on, the proxy will use HTTP2 by default and update the connection
            # to HTTP/3 (QUIC/UDP). This is saver.
            http3_probe = false;

            # LOAD BALANCING:
            # "p2" means it will randomly alternate between the top 2 fastest servers.
            # "lb_estimator" makes it continuously re-evaluate which servers are currently the fastest.
            lb_strategy = "p2";
            lb_estimator = true;

            # ==========================================================
            # PRIVACY & LEAK PREVENTION (THE "ECH STABILITY" LAYER)
            # ==========================================================

            # Stops IPv6 DNS lookups entirely. This prevents "Happy Eyeballs" latency
            # and closes a common privacy leak where IPv6 bypasses your proxy.
            block_ipv6 = !cfg.query.ipv6;

            # ==========================================================
            # BOOTSTRAP
            # ==========================================================

            # BYPASS RACE CONDITION:
            # Normally, dnscrypt-proxy pings 9.9.9.9:53 on startup to see if the internet
            # is awake. Because our firewall drops standard port 53 traffic to prevent leaks,
            # this ping would fail and the proxy would crash. Setting this to 0 skips the check.
            netprobe_timeout = 0;

            # BOOTSTRAP RESOLVERS:
            # Chicken-Egg: How do you find the IP address of "dns.quad9.net" to establish an HTTPS
            # tunnel, if you don't have a DNS server yet?
            # These standard IPs are used *only once* at boot to translate the DoH hostnames into IPs.
            # They are never used for your actual web browsing queries.
            bootstrap_resolvers = [
              "9.9.9.9:53" # Quad9
              "149.112.112.9:53" # Quad9 alt-1
              "149.112.112.112:53" # Quad9 alt-2
              "1.1.1.1:53" # Cloudflare
              "1.0.0.1:53" # Cloudflare alt-1
              "194.242.2.2:53" # Mullvad DNS
            ];

            # LOCAL BINDING:
            # Listen strictly on the local loopback, but on a custom port (5353).
            # This keeps standard port 53 free for systemd-resolved's stub listener.
            # Alternative: Use a second inerface 127.0.0.2
            listen_addresses = [
              "127.0.0.1:5353"
              "[::1]:5353"
            ];

            # ==========================================================
            # DATABASES
            # ==========================================================
            sources.public-resolvers = {
              urls = [
                "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
                "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
              ];
              cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
              minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
              refresh_delay = 24; # in hours
              prefix = "";
            };
            sources.quad9-resolvers = {
              urls = [
                "https://quad9.net/dnscrypt/quad9-resolvers.md"
                "https://raw.githubusercontent.com/Quad9DNS/dnscrypt-settings/main/dnscrypt/quad9-resolvers.md"
              ];
              minisign_key = "RWQBphd2+f6eiAqBsvDZEBXBGHQBJfeG6G+wJPPKxCZMoEQYpmoysKUN";
              cache_file = "/var/lib/dnscrypt-proxy/quad9-resolvers.md";
              refresh_delay = 24;
              prefix = "quad9-";
            };
            sources.relays = {
              urls = [
                "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
                "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
              ];
              cache_file = "/var/lib/dnscrypt-proxy/relays.md";
              minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
              refresh_delay = 24;
            };

            # ==========================================================
            # GENERAL FILTER
            # ==========================================================

            # Filter sources on IP Stack
            ipv4_servers = true;
            ipv6_servers = cfg.query.ipv6 || cfg.query.viaProxy; # Do not contact DNS server over IPv6 (my IPv6 is unique and can leak data)
            # Filter sources on protocol
            dnscrypt_servers = cfg.query.protocol == "dnscrypt" || cfg.query.protocol == "dnscrypt-ecs";
            doh_servers = cfg.query.protocol == "doh" || cfg.query.protocol == "doh-ecs";
            odoh_servers = cfg.query.protocol == "odoh";

            # ==========================================================
            # (OPTION-A): Dynamic Sources & Require Filters
            # Note: Because Option-B (server_names) is defined below, dnscrypt-proxy
            # operates in "Static" mode and will completely IGNORE this Option-A block.
            # It is kept here for reference if you ever want to switch back to dynamic.
            #
            # Auto-discover DNS servers from these sources
            # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Configuration-Sources
            # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/DNS-server-sources
            # ==========================================================
            require_dnssec = true; # Servers must support DNS security extensions (DNSSEC)
            require_nolog = true; # Servers must not log
            require_nofilter = false; # Servers can implement their own DNS blocking (e.g. adblocking)

            # ==========================================================
            # (OPTION-B): Static Server List (CURRENTLY ACTIVE)
            # By defining an exact list of servers, we enforce strict control over
            # where our traffic goes. We exclusively define Quad9's DoH (DNS-over-HTTPS).
            # This will override and irnogre OPTION-A's sources.public-resolvers list and their filters.
            # ==========================================================
            server_names = activeServerNames;
          }

          # ==========================================================
          # ANONYMIZER / PROXIES
          # ==========================================================
          (lib.mkIf cfg.query.viaProxy {
            anonymized_dns = {
              # if a server cannot accept traffic through a relay, do not bypass the relay.
              # Drop that server entirely and pretend it doesn't exist.
              # This guarantees the real IP is never accidentally leaked in relay mode.
              skip_incompatible = true;

              routes = activeRelays;
            };
          })

          # ==========================================================
          # LOCAL DOD Server
          # ==========================================================
          # This allows Chromium to connect to dnscrypt-proxy securely, enabling ECH.
          (lib.mkIf cfg.localDoh.enable {
            local_doh = {
              listen_addresses = [
                "127.0.0.1:${toString cfg.localDoh.port}"
                "[::1]:${toString cfg.localDoh.port}"
              ];
              path = cfg.localDoh.path;
              # These paths match exactly where our preStart script generates them
              cert_file = "/var/lib/dnscrypt-proxy/certs/localhost.pem";
              cert_key_file = "/var/lib/dnscrypt-proxy/certs/localhost-key.pem";
            };
          })

          # ==========================================================
          # MONITORING & LATENCY DASHBOARD
          # ==========================================================
          (lib.mkIf cfg.localMonitoring.enable {
            # This enables a web-based dashboard to see exactly how fast your
            # DNS queries are and which servers are currently winning the race.
            monitoring_ui = {
              enabled = true;
              # We use 4400 to avoid common port conflicts with web development (8080)
              listen_address = "127.0.0.1:${toString cfg.localMonitoring.port}";

              # Since it's local only, a simple username/password is fine
              username = cfg.localMonitoring.user;
              password = cfg.localMonitoring.pass;

              # REUSE YOUR EXISTING CERTS (from your localDoh setup)
              # This makes the dashboard load over HTTPS.
              tls_certificate = "/var/lib/dnscrypt-proxy/certs/localhost.pem";
              tls_key = "/var/lib/dnscrypt-proxy/certs/localhost-key.pem";

              # INSIGHT SETTINGS
              enable_query_log = true; # Required to see the live scrolling list

              # Default: 100
              max_query_log_entries = 300;

              # Privacy Levels:
              # 0 = Show everything (Best for debugging your Chrome/System flow)
              # 1 = Hide client IPs (Safe default)
              # 2 = Hide everything but basic stats
              privacy_level = 0;
            };
          })
          # ==========================================================
          # BLOCK/BLACK LIST
          # ==========================================================
          (lib.mkIf cfg.localBlockList.enable {
            blocked_names = {
              blocked_names_file = "/var/lib/dnscrypt-proxy/blocked-names.txt";
              log_file = "/var/lib/dnscrypt-proxy/blocked-names.log";
              log_format = "tsv";
            };
          })

          (lib.mkIf (builtins.length cfg.whitelist > 0) {
            allowed_names = {
              # Nix automatically turns this string array into a text file in the /nix/store
              allowed_names_file = "${pkgs.writeText "allowed-names.txt" (
                builtins.concatStringsSep "\n" cfg.whitelist
              )}";
              log_file = "/var/lib/dnscrypt-proxy/allowed-names.log";
              log_format = "tsv";
            };
          })
        ];
      }; # end of services.dnscrypt-proxy


      ###
      ### Blocklist download / update
      ###
      # (1/2) The Service: Defines HOW to download the list
      systemd.services.dnscrypt-proxy-update-blocklist = lib.mkIf cfg.localBlockList.enable {
        description = "Download fresh OISD blocklist for dnscrypt-proxy";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          # We use curl to download it directly to the mutable path
          ExecStart =
            let
              safeUrls = lib.concatStringsSep " " (map lib.escapeShellArg cfg.localBlockList.urls);
              downloadScript = pkgs.writeShellScript "update-blocklists.sh" ''
                ${pkgs.curl}/bin/curl -sSL ${safeUrls} > /var/lib/dnscrypt-proxy/blocked-names.txt
              '';
            in
            "${downloadScript}";

          # Ensure the proxy can read the file
          ExecStartPost = [
            "${pkgs.coreutils}/bin/chmod 664 /var/lib/dnscrypt-proxy/blocked-names.txt"
            # Silently reload the proxy cache so it applies immediately without breaking connections
            "+-${pkgs.procps}/bin/pkill -HUP dnscrypt-proxy"
          ];
          DynamicUser = true;
          Group = "dnscrypt";
          StateDirectory = "dnscrypt-proxy";
          StateDirectoryMode = "0775";
        };
      };
      # (2/2) The Timer: Defines WHEN to run the service
      systemd.timers.dnscrypt-proxy-update-blocklist = lib.mkIf cfg.localBlockList.enable {
        description = "Run OISD update weekly";
        timerConfig = {
          OnCalendar = "weekly"; # Or "daily" if you prefer
          Persistent = true; # Runs immediately if the machine was off during scheduled time
        };
        wantedBy = [ "timers.target" ];
      };

      # BOOTSTRAP FIREWALL GROUP:
      # By default NixOS will create a temporary user (not existing in /etc/group or /etc/passwd).
      # This creates an issue when we want to reference this user/group in our firewall rules,
      # as the firewall starts before the temporary user is created.
      # Fix: We assign dnscrypt-proxy a dedicated system group, so we can reference it in
      # our nftables.
      # Nftables will contain a rule saying: "Block all outbound port 53 traffic
      # EXCEPT for traffic originating from the 'dnscrypt' group." This allows the proxy
      # to use the bootstrap_resolvers while keeping the rest of the OS strictly locked down.
      users.groups.dnscrypt = {
        gid = 10053;
      };
      systemd.services.dnscrypt-proxy =
        let
          # Extract the directory path (e.g., "/run/local-doh-ca") and name (e.g., "local-doh-ca")
          caDir = builtins.dirOf cfg.localDoh.caCertPath;
          caDirName = builtins.baseNameOf caDir;
        in
        {

          serviceConfig = lib.mkMerge [
            {
              # UNCONDITIONAL: Required for the bootstrap firewall rules
              Group = "dnscrypt";
              # Ensure the StateDirectory is explicitly created for our certs
              # With this, systemd automatically creates the directory /var/lib/dnscrypt-proxy before
              # the service starts, sets the correct ownership to the service's user,
              # and ensures the data inside persists across reboots.
              StateDirectory = "dnscrypt-proxy";
              StateDirectoryMode = "0775";
            }
            (lib.mkIf cfg.localDoh.enable {
              # CONDITIONAL
              # This creates /run/local-doh-ca with 0755 permissions so your user can read it
              RuntimeDirectory = lib.mkForce "dnscrypt-proxy ${caDirName}";
              RuntimeDirectoryMode = "0755";
            })
          ];
          preStart = ''
            # =================================================================
            # BOOTSTRAP BLOCKLIST (Fixes the "File Not Found" crash on first boot)
            # =================================================================
            ${lib.optionalString cfg.localBlockList.enable ''
              if [ ! -f "/var/lib/dnscrypt-proxy/blocked-names.txt" ]; then
                echo "Bootstrapping empty blocklist..."
                touch "/var/lib/dnscrypt-proxy/blocked-names.txt"
                # ADD: Assign the empty file to the shared dnscrypt group
                chgrp dnscrypt "/var/lib/dnscrypt-proxy/blocked-names.txt"
                # EDIT: Changed 644 to 664 so the updater service can overwrite it
                chmod 664 "/var/lib/dnscrypt-proxy/blocked-names.txt"
              fi
            ''}
            # =================================================================
            # 2. GENERATE LOCAL DOH CERTIFICATES (If enabled)
            # =================================================================
            ${lib.optionalString cfg.localDoh.enable ''
              # --- GENERATE CERTIFICATES ---
              CERT_DIR="/var/lib/dnscrypt-proxy/certs"

              mkdir -p "$CERT_DIR"
              export CAROOT="$CERT_DIR"

              # Generate a custom Root CA with OpenSSL so we can name it whatever we want!
              # Change the -subj fields to whatever Organization (O) and Common Name (CN) you prefer.
              if [ ! -f "$CERT_DIR/rootCA.pem" ] || [ ! -f "$CERT_DIR/rootCA-key.pem" ]; then
                echo "Generating Custom Root CA with OpenSSL..."
                ${pkgs.openssl}/bin/openssl genrsa -out "$CERT_DIR/rootCA-key.pem" 3072
                ${pkgs.openssl}/bin/openssl req -x509 -new -nodes -key "$CERT_DIR/rootCA-key.pem" \
                  -sha256 -days 3650 -out "$CERT_DIR/rootCA.pem" \
                  -subj "/O=dnscrypt-proxy listener for local DoH/CN=(localhost) dnscrypt-proxy" \
                  -addext "basicConstraints=critical,CA:TRUE" \
                  -addext "keyUsage=critical,keyCertSign,cRLSign"
              fi

              if [ ! -f "$CERT_DIR/localhost.pem" ] || [ ! -f "$CERT_DIR/localhost-key.pem" ]; then
                echo "Generating local DoH certificates using mkcert..."

                # mkcert will detect the custom Root CA we just made and use it instead of generating its own!
                ${pkgs.mkcert}/bin/mkcert -install
                ${pkgs.mkcert}/bin/mkcert -cert-file "$CERT_DIR/localhost.pem" \
                                          -key-file "$CERT_DIR/localhost-key.pem" \
                                          localhost 127.0.0.1 ::1

                # Restrict permissions so only dnscrypt-proxy can read the private key
                chmod 644 "$CERT_DIR/localhost.pem"
                chmod 640 "$CERT_DIR/localhost-key.pem"
                chgrp dnscrypt "$CERT_DIR/localhost-key.pem"
              fi

              # Expose the public Root CA via the RAM-backed RuntimeDirectory
              cp "$CERT_DIR/rootCA.pem" "${cfg.localDoh.caCertPath}"
              chmod 644 "${cfg.localDoh.caCertPath}"
            ''}
          '';
        };

      ###
      ### 2. Uplink Routing
      ###
      # This tells systemd-resolved that its uplink is our dnscrypt-proxy server.
      # /nix/var/nix/profiles/system/etc/systemd/resolved.conf
      networking.nameservers = [
        "127.0.0.1:5353"
        "[::1]:5353"
      ];

      ###
      ### 3. Resolvd - Local DNS Resolver
      ###
      services.resolved = {
        enable = true;

        # PREVENT LOCAL LEAKS:
        # Disable legacy Microsoft and Apple local discovery protocols. If you typo a URL,
        # these protocols will loudly broadcast your typo to everyone on your local Wi-Fi.
        llmnr = "false";
        extraConfig = ''
          MulticastDNS=no
          # Disable caching here to prevent desynchronization, since dnscrypt-proxy caches.
          Cache=no
          CacheFromLocalhost=no
        '';

        # PREVENT SERVFAIL:
        # dnscrypt-proxy is already fully validating DNSSEC signatures. If resolved tries
        # to validate them a second time, it often strips the signatures and breaks the connection.
        dnssec = "false";
        dnsovertls = "false";

        # THE CATCH-ALL ROUTE:
        # The "~." means "root of the internet". This forces systemd-resolved to intercept
        # ALL global DNS queries and send them to the 'networking.nameservers' defined above,
        # which is dnscrypt-proxy.
        # It acts as a safety net ensuring no app bypasses the proxy.
        domains = [ "~." ];

        # FAIL CLOSED:
        # If dnscrypt-proxy crashes, we want the internet to break immediately.
        # Emptying this list prevents resolved from silently falling back to Google or
        # Cloudflare in plaintext.
        fallbackDns = [ ];
      };
    })

    # Global Activation Script
    # This guarantees the cleanup logic executes during 'nixos-rebuild switch' even if
    # the dnscrypt-proxy service is completely disabled and destroyed.
    (lib.mkIf (!cfg.enable || (!cfg.localDoh.enable && !cfg.localMonitoring.enable)) {
      system.activationScripts.cleanupDnscryptCerts = {
        text = ''
          CERT_DIR="/var/lib/dnscrypt-proxy/certs"
          if [ -d "$CERT_DIR" ]; then
            echo "Local DoH is disabled. Scrubbing orphaned certificates from state directory..."
            rm -rf "$CERT_DIR"
          fi
        '';
      };
    })
  ];
}
