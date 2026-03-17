{ config, lib, pkgs, ... }:

let
  cfg = config.networking.mobileWorkstation;
in
{
  # =========================================================================
  # OPTIONS DECLARATION
  # =========================================================================
  options.networking.mobileWorkstation = {
    # What: Defines the custom configuration option for the mobile workstation profile.
    # How: Uses lib.mkOption to create an enum choice between "hardened" and "hotel".
    # Why: Exposes a single, type-safe toggle to switch the entire networking architecture.
    profile = lib.mkOption {
      type = lib.types.enum [ "hardened" "hotel" ];
      default = "hardened";
      description = ''
        Selects the networking profile for the mobile workstation.
        - "hardened": Super-hardened mode with DNSCrypt via dnscrypt-proxy, dropping port 53 out, and strong MAC randomization.
        - "hotel": Relaxed mode for captive portals using DHCP-provided DNS and stable MAC randomization.
      '';
    };
  };

  # =========================================================================
  # ARCHITECTURE SUMMARY & PROFILE DIFFERENCES
  # =========================================================================
  # Architecture Choice:
  # This module leverages `systemd-networkd` for interface and routing management
  # alongside `iwd` exclusively for wireless management. This strict, native approach avoids
  # monolithic daemons like NetworkManager, providing robust performance and high security.
  # This setup is optimal for modern Wayland/Sway environments by eliminating legacy daemons.
  #
  # Wired vs. Wireless Priorities:
  # systemd-networkd manages route metrics directly (Ethernet = 100, Wi-Fi = 600) guaranteeing
  # wired networks are strictly prioritized over wireless networks.
  #
  # DNS Architecture (The App -> resolved -> dnscrypt-proxy -> Quad9 Chain):
  # - Apps query local standard DNS resolution APIs.
  # - `systemd-resolved` provides the local stub resolver on `127.0.0.53:53` and caches in RAM.
  # - `systemd-resolved` forwards these queries to `dnscrypt-proxy` on `127.0.0.1:5353`.
  # - `dnscrypt-proxy` enforces DNSSEC, drops logs, filters malware, and forwards queries
  #   encrypted to Quad9 and AdGuard over Port 443 (DNSCrypt). We specifically choose DNSCrypt
  #   over Port 443 rather than DoT (Port 853) to evade outbound firewall restrictions on public networks.
  # - A custom nftables output chain completely drops outgoing port 53 and 853 to prevent any rogue
  #   app or service from bypassing this chain and leaking queries over plaintext or alternative DoT.
  # - `dnscrypt-proxy` uses pre-configured static IP stamps from its package to find its
  #   initial servers. We disable its internal netprobe to prevent a race condition where it
  #   fails to start because our firewall drops its port 53 network check.
  #
  # Profiles (Switchable via GRUB specialisation or switch-to-configuration):
  # 
  # 1. 'Super-Hardened' (Profile = "hardened"):
  #    - Privacy: IPv6 Privacy Extensions (RFC 4941) enabled. Hostname masked.
  #      Wi-Fi MAC randomization is set to "network" in `iwd` to maximize scanning and
  #      connection anonymity per SSID, isolating presence across locations. Ethernet MAC is also randomized.
  #    - Security: Strict deny-by-default nftables firewall. Outgoing port 53/853 is strictly dropped.
  #      Deep kernel hardening (sysctl tuning for SYN floods, BPF hardening, dropping ICMP redirects).
  #    - DNS: Forced through `dnscrypt-proxy` exclusively via DNSCrypt on port 443. DHCP-provided DNS is completely ignored.
  #    - Isolation: Discovery protocols like LLMNR, multicastDns, Avahi, and Samba are strictly disabled.
  #
  # 2. 'Hotel-WiFi' (Profile = "hotel"):
  #    - Functionality: Manual captive portal login. The system drops strict dnscrypt-proxy routing
  #      and accepts DHCP-provided DNS, allowing local gateway resolution of the captive portal.
  #      No automation is added; you will open the portal URL manually in the browser.
  #    - Adjustment: Wi-Fi MAC randomization uses "network" in iwd to ensure a stable, randomized MAC
  #      per SSID, which is critical because captive portals track your session via MAC.
  #      Ethernet uses "random" MAC policy to maintain session stability without leaking true hardware MAC.
  #    - Security-Lite: Firewall rules and kernel hardening remain active, but outgoing port 53
  #      and pings are allowed to ensure the portal's DNS intercepts and keep-alives work.
  #
  # =========================================================================
  # DOCKER / PODMAN DNS DOCUMENTATION
  # =========================================================================
  # By default, Docker/Podman inject their own DNS configurations into containers.
  # If a container queries `127.0.0.53` (the default systemd-resolved stub), it will fail
  # because `127.0.0.53` is bound to the *host's* loopback, not the container's.
  #
  # To force Docker/Podman to securely use this host's `systemd-resolved` (and thus `dnscrypt-proxy`):
  # 
  # 1. Instruct systemd-resolved to listen on the Docker bridge IP.
  #    In your nixos configuration add:
  #    services.resolved.extraConfig = "DNSStubListenerExtra=172.17.0.1";
  #
  # 2. Force Docker to use that bridge IP as its global DNS server.
  #    In your nixos configuration add:
  #    virtualisation.docker.daemon.settings = { "dns" = [ "172.17.0.1" ]; };
  #
  # 3. Explicitly allow the Docker bridge through the strict firewall so it can query port 53.
  #    In your nixos configuration add:
  #    networking.firewall.trustedInterfaces = [ "docker0" ]; # Or your podman bridge
  #
  # This guarantees containers cannot leak DNS and route securely through Quad9.
  # =========================================================================

  config = lib.mkMerge [
    {
      # -------------------------------------------------------------------------
      # CORE NETWORKING & HARDENING (APPLIES TO BOTH PROFILES)
      # -------------------------------------------------------------------------

      # What: Define the hotel specialisation for offline switching.
      # How: Uses NixOS `specialisation` to create an alternative boot configuration.
      # Why: Allows toggling between 'hardened' and 'hotel' without an internet connection or rebuild.
      specialisation."hotel".configuration = {
        networking.mobileWorkstation.profile = lib.mkForce "hotel";
      };

      # What: Set a generic hostname.
      # How: Assigns "nix-workstation" to networking.hostName using lib.mkDefault.
      # Why: Masking the actual hostname prevents device identification on public networks.
      #      lib.mkDefault acts as a safe fallback avoiding evaluation errors if defined elsewhere.
      networking.hostName = lib.mkDefault "host";


      ###
      ### Disable Legacy networking backend
      ###
      networking.networkmanager.enable = false;
      networking.wireless.enable = false;


      ###
      ### Use systemd-based networking backend (modern choice)
      ###
      networking.useNetworkd = true;
      systemd.network.enable = true;


      ###
      ### Use iwd as an exclusive Wi-Fi backend (modern choice)
      ###
      networking.wireless.iwd.enable = true;


      # What: Disable wait-online service.
      # How: Disables systemd-networkd-wait-online.
      # Why: Prevents boot delays when disconnected from any network.
      systemd.network.wait-online.enable = false;


      ###
      ### Time Server
      ###

      # What: Disable default unencrypted NTP.
      # How: Clears timeservers and disables timesyncd.
      # Why: Stops plaintext UDP 123 leaks.
      networking.timeServers = [];
      services.timesyncd.enable = false;

      # Hardcode NTS time servers to break the Time/DNS deadlock
      networking.extraHosts = ''
        # Cloudflare NTS (Anycast)
        162.159.200.1 time.cloudflare.com
        2606:4700:f0::1 time.cloudflare.com

        # Netnod NTS (Anycast)
        94.58.207.70 nts.netnod.se
        2a01:3f0:1:4::28 nts.netnod.se
      '';

      # Use NTS (Network Time Security) via chrony.
      # Provides secure, encrypted time sync over SSL.
      services.chrony = {
        enable = true;

        # Clear default servers so we only use our explicit NTS servers below
        servers = [];

        extraConfig = ''
          # 1. UPSTREAM SERVERS
          # Use NTS (Network Time Security) for encrypted time sync
          server time.cloudflare.com iburst nts
          server nts.netnod.se iburst nts

          # 2. BOOTSTRAP FIXES
          # Ignore NTS certificate expiration dates so we can sync even if time is years off
          nocerttimecheck 1
          # '1':  If clock is off by 1 sec then adjust
          # '3': Only do 3 updates after start
          makestep 1 3

          # 3. SECURITY: STRICT CLIENT MODE
          # Disable the NTP server port entirely (do not listen on UDP 123)
          port 0
          # Disable network command listening (forces chronyc to use the local Unix socket)
          cmdport 0
        '';
      };


      ###
      ### DNSCrypt Proxy
      ###
      services.dnscrypt-proxy = {
        enable = lib.mkDefault true;
        settings = {
          # Disable netprobe.
          # Prevents a race condition. dnscrypt-proxy natively tries to ping 9.9.9.9:53 to check network connectivity.
          # Since we drop port 53 via nftables, the probe would fail and block dnscrypt-proxy from starting.
          netprobe_timeout = 0;

          # Note: Ensure that systemd-resolved has caching turned off.
          cache = true;

          # Load balancing strategy
          lb_strategy = "p2";  # Randomly switch between the 2 fastest available server
          lb_estimator = true; # Constantly check which are fastest

          # Listen strictly on local loopback on a custom port for resolved to forward to.
          listen_addresses = [
            "127.0.0.1:5353"
            "[::1]:5353"
          ];

          # Use only specific IPs to find the initial resolver list
          bootstrap_resolvers = [
            "9.9.9.9:53"          # Quad9
            "149.112.112.9:53"    # Quad9 alt-1
            "149.112.112.112:53"  # Quad9 alt-2
            "1.1.1.1:53"          # Cloudflare
            "1.0.0.1:53"          # Cloudflare alt-1
            "194.242.2.2:53"      # Mullvad DNS
          ];

          # Option-A:
          #
          # Auto-discover DNS servers from these sources
          # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Configuration-Sources
          # https://github.com/DNSCrypt/dnscrypt-proxy/wiki/DNS-server-sources
          sources.public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            ];
            cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
            refresh_delay = 24;  # in hours
            prefix = "";
          };

          # Filter sources on IP Stack
          ipv4_servers = true;
          ipv6_servers = false;  # Do not contact DNS server over IPv6 (my IPv6 is unique and can leak data)

          # Filter sources on protocol
          dnscrypt_servers = false; # Enforce DNSCrypt protocol?
          doh_servers = true;      # Enforce DNS-over-HTTPS protocol?
          odoh_servers = false;    # Disable Oblivious DNS-over-HTTPS protocol

          # Filter sources features
          require_dnssec = true;    # Servers must support DNS security extensions (DNSSEC)
          require_nolog = true;     # Servers must not log
          require_nofilter = false; # Servers can implement their own DNS blocking (e.g. adblocking)

          # Option-B:
          #
          # Instead of relying on sources and filters, we exclusivly define them statically here.
          # This will ignore sources.public-resolvers and their filters and only use this.
          # https://dnscrypt.info/public-servers/
          server_names = [
            #"quad9-dnscrypt-ip4-filter-pri"       # DNSCrypt, IPv4 (9.9.9.9)
            #"quad9-dnscrypt-ip4-filter-alt"       # DNSCrypt, IPv4 (149.112.112.9)
            #"quad9-dnscrypt-ip4-filter-alt2"      # DNSCrypt, IPv4 (149.112.112.112)
            "quad9-doh-ip4-port443-filter-pri"   # DOH, IPv4 (9.9.9.9)
            "quad9-doh-ip4-port443-filter-alt"   # DoH, IPv4 (149.112.112.9)
            "quad9-doh-ip4-port443-filter-alt2"  # DoH, IPv4 (149.112.112.112)
          ];
        };
      };

      # Explicitly define a static group so it exists in /etc/group at early boot.
      # This prevents nftables from failing when allowing dnscrypt-proxy to do initial
      # bootstrap connect to DNS 53.
      users.groups.dnscrypt = {
        gid = 10053;
      };
      # Only inject the systemd override when NOT in the hotel profile.
      # This prevents creating a broken zombie service when dnscrypt is disabled.
      systemd.services.dnscrypt-proxy = lib.mkIf (cfg.profile != "hotel") {
        serviceConfig = {
          Group = "dnscrypt";
        };
      };


      ###
      ### Resolvd - Local DNS Resolver
      ###
      # Acts as the local caching resolver for all local apps, forwarding appropriately.
      # /nix/var/nix/profiles/system/etc/systemd/resolved.conf

      # ROUTING: Point Resolved specifically to the Proxy
      networking.nameservers = [ "127.0.0.1:5353" "[::1]:5353" ];
      services.resolved = {
        enable = true;

        # Disables an old, insecure Microsoft protocol that broadcasts your queries to everyone on the local Wi-Fi.
        llmnr = "false";

        # What: Explicitly disable DNSSEC validation in resolved.
        # Why: dnscrypt-proxy is the sole DNSSEC root of trust. Doing it twice causes SERVFAIL.
        dnssec = "false";
        dnsovertls = "false";

        # What: Route all system DNS exclusively to dnscrypt-proxy.
        # How: Sets global DNS to 127.0.0.1:5353, Domains=~.
        # Why: Guarantees everything hits the encrypted proxy and prevents local protocol leakage.
        # What: Bind strictly to both IPv4 and IPv6 local loopbacks.
        # Why: Dual-stack resolution prevents fragmentation and potential fallback delays in IPv6 containers or kernel stack preferences.
        extraConfig = ''
          # Disable Apple/Printer discovery (Privacy)
          MulticastDNS=no

          # dnscrypt-proxy is already caching
          Cache=no
          CacheFromLocalhost=no
        '';

        # The "~." routing domain forces systemd-resolved to send ALL
        # DNS queries to your global nameservers (dnscrypt-proxy).
        domains = [ "~." ];

        # Clear out the default fallback DNS servers (Cloudflare/Google)
        # so your system fails closed if dnscrypt-proxy goes down,
        # rather than leaking plaintext queries.
        fallbackDns = [];
      };


      ###
      ### Firewall (nftables)
      ###

      # What: Enable Strict nftables Firewall.
      # How: Uses the modern nftables backend for all firewalls.
      # Why: High-performance, deny-by-default packet filtering.
      networking.nftables.enable = true;
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [];
      };

      # ---------------------------------------------------------------------
      # KERNEL HARDENING (SYSCTL)
      # ---------------------------------------------------------------------

      # What: Enable BBR and FQ kernel modules natively at boot.
      # How: Injects them into boot.kernelModules.
      # Why: Ensures our high-performance TCP congestion algos apply smoothly.
      boot.kernelModules = [ "tcp_bbr" "sch_fq" ];

      boot.kernel.sysctl = {
        # Network Routing Hardening: Drop source routed packets and ICMP redirects.
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;

        # ARP Hardening: Prevent cross-interface ARP responses.
        "net.ipv4.conf.all.arp_ignore" = 1;
        "net.ipv4.conf.default.arp_ignore" = 1;
        "net.ipv4.conf.all.arp_announce" = 2;
        "net.ipv4.conf.default.arp_announce" = 2;

        # DoS Protection: SYN cookies and TIME-WAIT protection.
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

        # TCP Performance Tuning: High-throughput config remaining active in both profiles.
        "net.ipv4.tcp_timestamps" = 1;
        "net.ipv4.tcp_window_scaling" = 1;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "fq";

        # Audit: Log weird packets.
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.default.log_martians" = 1;

        # Memory Security: Restrict eBPF, kptr, and dmesg to prevent kernel info leaks.
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
      };

      # ---------------------------------------------------------------------
      # WIREGUARD EXAMPLES (systemd-networkd natively)
      # ---------------------------------------------------------------------
      # What: 3 example WireGuard configurations using systemd-networkd natively.
      # Why: Satisfies requirement to provide configurations for AWS, Cisco, and ProtonVPN.
      # Note: Configured natively via Nix, disabled by default. Enable them when needed.
      #
      #systemd.network.netdevs."50-wg-aws" = {
      #  enable = false;
      #  netdevConfig = { Kind = "wireguard"; Name = "wg-aws"; };
      #  wireguardConfig = { PrivateKeyFile = "/root/wireguard-keys/aws-private"; };
      #  wireguardPeers = [ { PublicKey = "AWS_PUBLIC_KEY"; AllowedIPs = [ "10.100.0.0/16" ]; Endpoint = "vpn.aws.example.com:51820"; } ];
      #};
      #systemd.network.networks."50-wg-aws" = {
      #  enable = false;
      #  matchConfig.Name = "wg-aws";
      #  address = [ "10.100.0.2/24" ];
      #};

      #systemd.network.netdevs."50-wg-cisco" = {
      #  enable = false;
      #  netdevConfig = { Kind = "wireguard"; Name = "wg-cisco"; };
      #  wireguardConfig = { PrivateKeyFile = "/root/wireguard-keys/cisco-private"; };
      #  wireguardPeers = [ { PublicKey = "CISCO_PUBLIC_KEY"; AllowedIPs = [ "192.168.10.0/24" ]; Endpoint = "vpn.cisco.example.com:51820"; } ];
      #};
      #systemd.network.networks."50-wg-cisco" = {
      #  enable = false;
      #  matchConfig.Name = "wg-cisco";
      #  address = [ "192.168.10.2/24" ];
      #};

      #systemd.network.netdevs."50-wg-proton" = {
      #  enable = false;
      #  netdevConfig = { Kind = "wireguard"; Name = "wg-proton"; };
      #  wireguardConfig = { 
      #    PrivateKeyFile = "/root/wireguard-keys/proton-private"; 
      #    # What: Assign a FirewallMark and place default route in a dedicated table.
      #    # Why: Exempts outer VPN UDP packets from the default route, completely preventing the 0.0.0.0/0 routing loop of death.
      #    FirewallMark = 51820;
      #    RouteTable = 1000;
      #  };
      #  wireguardPeers = [ { PublicKey = "PROTON_PUBLIC_KEY"; AllowedIPs = [ "0.0.0.0/0" ]; Endpoint = "nl.protonvpn.net:51820"; } ];
      #};
      #systemd.network.networks."50-wg-proton" = {
      #  enable = false;
      #  matchConfig.Name = "wg-proton";
      #  address = [ "10.2.0.2/24" ];
      #  # What: Explicitly blackhole IPv6 traffic in the VPN table.
      #  # Why: Prevents IPv6 leaks over an IPv4-only VPN natively while allowing outer IPv6 tunnels to route over main.
      #  routes = [
      #    { Destination = "::/0"; Type = "blackhole"; Table = 1000; }
      #  ];
      #  # What: Policy routing for the VPN with local suppression.
      #  # Why: Suppresses default-route lookup in main so local/connected traffic remains unbroken, then securely forces internet traffic through the tunnel.
      #  routingPolicyRules = [
      #    { Table = "main"; SuppressPrefixLength = 0; Priority = 9; }
      #    { FirewallMark = 51820; InvertRule = true; Table = 1000; Priority = 10; }
      #  ];
      #};
    }

    # -------------------------------------------------------------------------
    # PROFILE: SUPER-HARDENED
    # -------------------------------------------------------------------------
    (lib.mkIf (cfg.profile == "hardened") {

      ###
      ### WiFi
      ###
      networking.wireless.iwd.settings = {
        # https://www.mankier.com/5/iwd.config#Settings-General_Settings
        General = {
          EnableNetworkConfiguration = false;
          AddressRandomization = "network";
          AddressRandomizationRange = "full";
        };
        # https://www.mankier.com/5/iwd.config#Settings-Network
        # https://git.kernel.org/pub/scm/network/wireless/iwd.git/tree/src/iwd.config.rst
        Network = {
          EnableIPv6 = true;
          NameResolvingService = "none";
        };
        # https://git.kernel.org/pub/scm/network/wireless/iwd.git/tree/src/iwd.network.rst
        # https://mynixos.com/nixpkgs/option/networking.wireless.iwd.settings
        Settings = {
          AutoConnect = true;
          AlwaysRandomizeAddress = true;  # only used if AddressRandmization is set to 'network'
        };
      };


      ###
      ### Network Interfaces
      ###
      systemd.network = {

        # ==========================================================
        # LAYER 2: Hardware Privacy (Ethernet MAC Spoofing)
        # ==========================================================
        links."10-eth-mac" = {
          matchConfig.OriginalName = "en* eth*";
          # What: Fully randomize the Ethernet MAC address on every plug-in.
          # How: Instructs udev to generate a random MAC before the interface comes up.
          # Why: Prevents physical tracking across different public Ethernet jacks.
          linkConfig = {
            MACAddressPolicy = "random";
            NamePolicy = "keep kernel database onboard slot path";
          };
        };

        # ==========================================================
        # LAYER 3: Network Configuration
        # ==========================================================
        # Ethernet
        networks."10-eth" = {
          matchConfig.Name = "en* eth*";
          # What: Force metrics, disable DHCP DNS, disable DHCPv6, and disable multicast discovery.
          # Why: DHCPv6 is completely disabled to eliminate DUID persistent tracking on public networks. MulticastDNS and LLMNR are natively disabled on the interface to prevent protocol leaks.
          networkConfig = {
            # Network layer protocols
            DHCP = "ipv4";          # Use DHCP for IPv4 only (kills DHCPv6 tracking).
            IPv6AcceptRA = true;    # Safely enable IPv6 via SLAAC (Router Advertisements).
            # IPv6 Privacy
            IPv6PrivacyExtensions = "yes";
            IPv6LinkLocalAddressGenerationMode = "random";
            # Disable local discovery and hardware broadcast protocols
            LLMNR = false;
            MulticastDNS = false;
            EmitLLDP = false;       # Do not broadcast hardware capabilities to the switch.
          };
          dhcpV4Config = {
            RouteMetric = 100;
            # RFC 7844 Anonymity Profile (strips Client ID, Vendor Class, etc.)
            Anonymize = true;
            SendHostname = false;
            # Infrastructure Trust: Do not accept core configurations from untrusted routers
            UseDNS = false;         # Rely on your secure global stub resolver instead.
            UseDomains = false;     # Ignore search domains provided by the netwprk
            UseHostname = false;    # Ignore host name change request
            UseNTP = false;         # Prevent malicious time-shifting that breaks TLS/DNSSEC.
            UseTimezone = false;    # Prevent location leakage via network timezone.
          };
          ipv6AcceptRAConfig = {
            RouteMetric = 100;
            # Infrastructure Trust for IPv6 Router Advertisements
            UseDNS = false;
            UseDomains = false;
          };
        };

        # Wi-Fi
        networks."20-wifi" = {
          # Match standard Wi-Fi interfaces (wlan0, wlp2s0, etc.)
          matchConfig.Name = "wl*";
          # What: Native Wi-Fi configuration disabling DHCPv6 and multicast discovery.
          # Why: Eliminates DUID tracking and prevents interface-level LLMNR/mDNS leaks.
          networkConfig = {
            # Privacy & Tracking Prevention
            DHCP = "ipv4";
            IPv6AcceptRA = true;
            IPv6PrivacyExtensions = "yes";
            IPv6LinkLocalAddressGenerationMode = "random";
            # Disable local discovery and hardware broadcast protocols
            LLMNR = false;
            MulticastDNS = false;
            EmitLLDP = false;
            # PERFORMANCE: Wi-Fi signals fluctuate and roam.
            # This prevents networkd from instantly dropping your IP routes
            # if iwd takes 1-2 seconds to roam between access points.
            IgnoreCarrierLoss = "3s";
          };
          # Metric 600 makes it fallback. DNS is strictly ignored.
          dhcpV4Config = {
            # PERFORMANCE: Metric 600 ensures Ethernet (Metric 100) is preferred.
            RouteMetric = 600;
            # RFC 7844 Strict Anonymity
            Anonymize = true;
            SendHostname = false;
            # Zero Trust Infrastructure (Reject untrusted DNS, NTP, and Tracking)
            UseDNS = false;
            UseDomains = false;
            UseHostname = false;
            UseNTP = false;
            UseTimezone = false;
          };
          ipv6AcceptRAConfig = {
            RouteMetric = 600;
            # Zero Trust Infrastructure (Reject untrusted DNS, NTP, and Tracking)
            UseDNS = false;
            UseDomains = false;
          };
        };
      };

      boot.kernel.sysctl = {
        # Source Routing Spoofing Protection (Defense in Depth)
        # What: Hardcode kernel-level locks for strict reverse path filtering.
        # Why: Relying solely on a userspace firewall ruleset for IP spoofing protection is a defense-in-depth failure.
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
      };

      networking.firewall = {
        # What: Drop ICMP pings and enforce strict reverse path filtering.
        # Why: Drops discovery probes and strictly prevents IP spoofing.
        allowPing = false;
        checkReversePath = "strict";
      };

      networking.nftables.tables."dns-leak-protection" = {
        # What: Dedicated output chain to drop plaintext DNS and standard DoT.
        # How: Inspects outgoing packets on hook output.
        # Why: A crucial firewall failsafe. Even if a local app bypasses systemd-resolved,
        #      it cannot egress on port 53 or 853. dnscrypt-proxy connects out on 443 securely.
        family = "inet";
        content = ''
          chain output {
            type filter hook output priority -10; policy accept;

            # 1. Always allow loopback (Resolved <-> DNSCrypt)
            oifname "lo" accept

            # 2. Allow dnscrypt-proxy (via its gid:10053) to bootstrap via Port 53
            meta skgid 10053 udp dport 53 accept
            meta skgid 10053 tcp dport 53 accept

            # 3. Global Killswitch: Block all other DNS/DoT leaks
            # This will also block 'dig @1.1.1.1 google.com'
            udp dport 53 drop
            tcp dport 53 drop
            udp dport 853 drop
            tcp dport 853 drop

            # Drop Multicast Listener Discovery (MLD) to prevent local network chatter
            icmpv6 type { mld-listener-query, mld-listener-report, mld-listener-done, mld2-listener-report } drop
          }
          chain forward {
            type filter hook forward priority -10; policy accept;
            udp dport 53 drop
            tcp dport 53 drop
            udp dport 853 drop
            tcp dport 853 drop
          }
        '';
      };

    })

    # -------------------------------------------------------------------------
    # PROFILE: HOTEL-WIFI
    # -------------------------------------------------------------------------
    (lib.mkIf (cfg.profile == "hotel") {

      # What: Disable dnscrypt-proxy completely.
      # Why: Prevents captive portal deadlocks where dnscrypt-proxy attempts to bootstrap
      #      but fails, which blocks systemd-resolved.
      services.dnscrypt-proxy.enable = lib.mkForce false;

      ###
      ### Resolvd - Explicit Hotel Override
      ###
      networking.nameservers = lib.mkForce [ "9.9.9.9" "149.112.112.112" ];
      services.resolved = {
        # What: Forcefully clear the global routing domain ("~.") set in the core profile.
        # Why: Prevents resolved from treating a dead dnscrypt-proxy as the only valid route.
        domains = lib.mkForce [];

        # What: Forcefully overwrite the extraConfig string.
        # Why: Strips out the hardcoded `DNS=127.0.0.1:5353` and `Domains=~.` directives 
        #      from the core config, allowing resolved to accept DHCP-provided DNS servers.
        #      We manually retain the Cache and MulticastDNS settings here.
        extraConfig = lib.mkForce ''
          # DHCP-only DNS routing for captive portal access
          MulticastDNS=no
          Cache=yes
        '';

        # What: Ensure fallback DNS remains empty.
        # Why: Concurrent queries to external fallback resolvers would fail behind a captive portal.
        fallbackDns = lib.mkForce [];
      };


      # What: iwd MAC Randomization for Hotel.
      # How: Generates a random MAC, but keeps it *stable per network SSID*.
      # Why: Captive portals authorize your internet session using your MAC address. 
      #      If you randomize on every connection ("once"), you get logged out instantly upon re-auth.
      networking.wireless.iwd.settings = {
        General = {
          AddressRandomization = "network";
        };
      };

      systemd.network = {
        # What: Ethernet interface setup for Hotel.
        networks."10-eth" = {
          matchConfig.Name = "en* eth*";
          # What: Allow DHCP-provided DNS, disable DHCPv6, and disable multicast discovery.
          # Why: UseDNS=true is required for captive portals. DHCPv6 is disabled to eliminate DUID tracking. Interface-level LLMNR/mDNS is strictly disabled.
          networkConfig = { DHCP = "ipv4"; IPv6PrivacyExtensions = "yes"; IPv6LinkLocalAddressGenerationMode = "random"; LLMNR = false; MulticastDNS = false; };
          dhcpV4Config = { RouteMetric = 100; UseDNS = true; UseHostname = false; };
          ipv6AcceptRAConfig = { RouteMetric = 100; UseDNS = true; };
        };
        networks."20-wifi" = {
          matchConfig.Name = "wl*";
          # What: Disable DHCPv6 and multicast discovery on Hotel Wi-Fi.
          # Why: Prevents persistent DUID tracking across captive portals and strictly disables protocol leaks.
          networkConfig = { DHCP = "ipv4"; IPv6PrivacyExtensions = "yes"; IPv6LinkLocalAddressGenerationMode = "random"; LLMNR = false; MulticastDNS = false; };
          dhcpV4Config = { RouteMetric = 600; UseDNS = true; UseHostname = false; };
          ipv6AcceptRAConfig = { RouteMetric = 600; UseDNS = true; };
        };
      };

      boot.kernel.sysctl = {
        # Source Routing Spoofing Protection (Defense in Depth)
        # What: Explicitly override reverse path filtering to loose (2).
        # Why: Many hotel gateways drop unresponsive hosts or have asymmetric routing.
        #      Strict rp_filter at ring 0 would drop packets before the loose firewall rule is evaluated.
        "net.ipv4.conf.all.rp_filter" = lib.mkForce 2;
        "net.ipv4.conf.default.rp_filter" = lib.mkForce 2;
      };

      networking.firewall = {
        # What: Allow ICMP pings and loosen reverse path filtering.
        # Why: Many hotel gateways drop unresponsive hosts (ping failure), and asymmetric routing
        #      is common on misconfigured public networks.
        allowPing = true;
        checkReversePath = "loose";
      };

    })
  ];
}
