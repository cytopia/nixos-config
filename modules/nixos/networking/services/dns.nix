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
{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.networking.service.dns;
in
{
  #################################################################################################
  ###
  ### 1. OPTIONS
  ###
  #################################################################################################
  options.mySystem.networking.service.dns = {
    enable = lib.mkEnableOption "Enable dnscrypt proxy and local resolver";
  };

  #################################################################################################
  ###
  ### 2. CONFIGURATION
  ###
  #################################################################################################
  config = lib.mkIf cfg.enable {

    ###
    ### 1. DNSCrypt Proxy
    ###
    services.dnscrypt-proxy = {
      enable = lib.mkDefault true;
      settings = {
        # BYPASS RACE CONDITION:
        # Normally, dnscrypt-proxy pings 9.9.9.9:53 on startup to see if the internet
        # is awake. Because our firewall drops standard port 53 traffic to prevent leaks,
        # this ping would fail and the proxy would crash. Setting this to 0 skips the check.
        netprobe_timeout = 0;

        # CACHING:
        # We handle all DNS caching here at the proxy level rather than in resolved.
        cache = true;

        # LOAD BALANCING:
        # "p2" means it will randomly alternate between the top 2 fastest servers.
        # "lb_estimator" makes it continuously re-evaluate which servers are currently the fastest.
        lb_strategy = "p2";
        lb_estimator = true;

        # LOCAL BINDING:
        # Listen strictly on the local loopback, but on a custom port (5353).
        # This keeps standard port 53 free for systemd-resolved's stub listener.
        # Alternative: Use a second inerface 127.0.0.2
        listen_addresses = [
          "127.0.0.1:5353"
          "[::1]:5353"
        ];

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

        # =====================================================================
        # OPTION-A: Dynamic Sources & Filters
        # Note: Because Option-B (server_names) is defined below, dnscrypt-proxy
        # operates in "Static" mode and will completely IGNORE this Option-A block.
        # It is kept here for reference if you ever want to switch back to dynamic.
        #
        # Auto-discover DNS servers from these sources
        # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Configuration-Sources
        # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/DNS-server-sources
        # =====================================================================
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
        # Filter sources on IP Stack
        ipv4_servers = true;
        ipv6_servers = false; # Do not contact DNS server over IPv6 (my IPv6 is unique and can leak data)
        # Filter sources on protocol
        dnscrypt_servers = false; # Disable DNSCrypt protocol?
        doh_servers = true; # Enforce DNS-over-HTTPS protocol?
        odoh_servers = false; # Disable Oblivious DNS-over-HTTPS protocol
        # Filter sources features
        require_dnssec = true; # Servers must support DNS security extensions (DNSSEC)
        require_nolog = true; # Servers must not log
        require_nofilter = false; # Servers can implement their own DNS blocking (e.g. adblocking)

        # =====================================================================
        # OPTION-B: Static Server List (CURRENTLY ACTIVE)
        # By defining an exact list of servers, we enforce strict control over
        # where our traffic goes. We exclusively define Quad9's DoH (DNS-over-HTTPS).
        # This will override and irnogre OPTION-A's sources.public-resolvers list and their filters.
        # =====================================================================
        server_names = [
          # https://dnscrypt.info/public-servers/
          #"quad9-dnscrypt-ip4-filter-pri"       # DNSCrypt, IPv4 (9.9.9.9)
          #"quad9-dnscrypt-ip4-filter-alt"       # DNSCrypt, IPv4 (149.112.112.9)
          #"quad9-dnscrypt-ip4-filter-alt2"      # DNSCrypt, IPv4 (149.112.112.112)
          "quad9-doh-ip4-port443-filter-pri" # DOH, IPv4 (9.9.9.9)
          "quad9-doh-ip4-port443-filter-alt" # DoH, IPv4 (149.112.112.9)
          "quad9-doh-ip4-port443-filter-alt2" # DoH, IPv4 (149.112.112.112)
        ];
      };
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
    systemd.services.dnscrypt-proxy = {
      serviceConfig = {
        Group = "dnscrypt";
      };
    };

    ###
    ### 2. Uplink Routing
    ###
    # This tells systemd-resolved that its "ISP" is actually our dnscrypt-proxy port.
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
  };
}
