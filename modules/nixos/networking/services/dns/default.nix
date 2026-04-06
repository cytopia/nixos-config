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

{ config, lib, ... }:
let
  cfg = config.cytopia.service.dns;
in
{
  imports = [
    ./servers.nix # Mandatory server data
    ./feature-blocklist.nix # Optional
    ./feature-certs.nix # Optional (Shared by DoH & UI)
    ./feature-firewall.nix # Optional
    ./feature-local-doh.nix # Optional
    ./feature-monitoring.nix # Optional
  ];

  ###
  ### CORE OPTIONS
  ###
  options.cytopia.service.dns = {
    enable = lib.mkEnableOption "Enable dnscrypt proxy and local resolver";

    # INTERNAL OPTION: Define a hidden, internal constant for the GID
    internal.proxyGid = lib.mkOption {
      type = lib.types.int;
      default = 10053;
      internal = true; # Hides it from 'man configuration.nix' and documentation
      description = ''
        The static dnscrypt-proxy group ID used for firewall bootstrap routing
        and systemd unit files internally across this module.
      '';
    };

    query = {
      protocol = lib.mkOption {
        type = lib.types.enum [
          "doh" # stealthiest protocol
          "doh-ecs" # with subnet forwarding (privacy leak)
          "dnscrypt" # Security & Speed
          "dnscrypt-ecs" # with subnet forwarding (privacy leak)
          "odoh" # Anonymous, but suspicious
        ];
        default = "doh";
        description = "Choose protocol to fetch DNS records. DoH: most stealth.";
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
        description = "Enable/Disable to query via IPv6. Best to leave off.";
      };
      viaProxy = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Proxy encrypted DNS requests through a middle-server.";
      };
    };

  };

  ###
  ### 2. CORE CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Core identity must be defined here so features like certs/firewall can rely on it
    users.groups.dnscrypt.gid = cfg.internal.proxyGid;

    systemd.services.dnscrypt-proxy.serviceConfig = {
      # Tell the proxy to run under this group name
      Group = "dnscrypt";
      # Ensure the StateDirectory is explicitly created for our certs/databases
      StateDirectory = "dnscrypt-proxy";
      StateDirectoryMode = "0775";
    };


    ###
    ### NETWORK MANAGER INTEGRATION
    ###
    # If NetworkManager is enabled anywhere else on the system,
    # we must forcefully intercept its DNS handling so it doesn't push ISP
    # nameservers to resolv.conf or systemd-resolved, bypassing our proxy.
    networking.networkmanager = lib.mkIf config.networking.networkmanager.enable {
      dns = lib.mkForce "none";
      settings = {
        main = {
          systemd-resolved = lib.mkForce false;
        };
      };
    };


    ###
    ### 1. DNSCrypt Proxy
    ###
    # https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
    services.dnscrypt-proxy = {
      enable = lib.mkDefault true;
      settings = {
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


        # [FIX: Static server names and anonymized_dns are now handled by servers.nix]
        # [FIX: Local DoH, Monitoring, and Blocklists are handled by their respective feature files]
      };

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
      # Emptying this list prevents resolved from silently falling back to Google or
      # Cloudflare in plaintext.
      fallbackDns = [ ];
    };
  };

}
