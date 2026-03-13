{ config, pkgs, ... }:

{
  # https://gemini.google.com/app/8f8069368931bc44

  # If a Hotel login does not work
  # simply visit this page in the browser: http://neverssl.com.


  # Set hostname
  networking.hostName = "nixbtw";

  # This tells NixOS: "I am using systemd-networkd for EVERYTHING."
  # It automatically disables dhcpcd and the old scripts.
  networking.useNetworkd = true;
  networking.useDHCP = false; # We define DHCP per-interface below

  # 1. Disable the heavy hitters
  networking.networkmanager.enable = false;
  networking.wireless.enable = false;
  #networking.networkmanager.wifi.backend = "iwd";





  ###
  ### WiFi (iwd)
  ###
  networking.wireless.iwd = {
    enable = true;
    settings = {
      Network = {
        EnableIPv6 = true;
        # CRITICAL: Tell IWD to stay away from IP/DNS logic
        # systemd-networkd will handle this.
        EnableNetworkConfiguration = false;
      };
      # https://git.kernel.org/pub/scm/network/wireless/iwd.git/tree/src/iwd.network.rst
      Settings = {
        AutoConnect = true;
        AlwaysRandomizeAddress = true;  # only used if AddressRandmization is set to 'network'
      };
      General = {
        AddressRandomization = "network";
        #AddressRandomizationRange = "full";
      };
    };
  };


  ###
  ### SYSTEMD-NETWORKD (IP Management)
  ###

  # 3. Use systemd-networkd for Wired + Wireless IP management
  systemd.network = {
    enable = true;
    wait-online.enable = false; # Prevents long boot times if offline

    # Configure Wired (Ethernet) - Matches any name starting with 'e' (eth0, enp3s0, etc)
    networks."10-wired" = {
      matchConfig.Name = "e*";
      networkConfig = {
        DHCP = "yes";
        DNSOverTLS = true;
        IPv6PrivacyExtensions = "kernel"; # DON'T leak your MAC address to the web
        MulticastDNS = false;             # Stop listening on UDP 5353
        LLMNR = false;                    # Stop listening on UDP 5355
      };
      dhcpV4Config = {
        RouteMetric = 10; # Lower is preferred
        UseDNS = false;
      };
      dhcpV6Config = {
        RouteMetric = 10; # Lower is preferred
        UseDNS = false;
      };
    };

    # Configure Wireless - Matches any name starting with 'w'
    networks."20-wireless" = {
      matchConfig.Name = "w*";
      networkConfig = {
        DHCP = "yes";
        DNSOverTLS = true;
        IPv6PrivacyExtensions = "kernel"; # DON'T leak your MAC address to the web
        MulticastDNS = false;             # Stop listening on UDP 5353
        LLMNR = false;                    # Stop listening on UDP 5355
      };
      # Ensure wired is preferred over wireless if both are plugged in
      dhcpV4Config = {
        RouteMetric = 20; # Lower is preferred
        UseDNS = false;   # Set to true, if hotel login does not work
      };
      dhcpV6Config = {
        RouteMetric = 20; # Lower is preferred
        UseDNS = false;
      };
    };
  };


  ###
  ### Secure DNS
  ###

  #  Custom DNS Overwrite via systemd-resolved
  services.resolved = {
    enable = true;

    # This allows Hotel wifis to inject their own DNS for a login page
    #dnssec = "true";
	dnssec = "allow-downgrade"; # FIXED: Allows portals to work, then re-enables security

    dnsovertls = "true";  # Set to "strict" if you want NO internet rather than unencrypted internet

    # FIXED: Explicitly disable LLMNR at the NixOS module level
    llmnr = "false";

    # FIXED: The global 'domains' list is redundant if using extraConfig,
    # but setting it to an empty list or ensuring extraConfig wins is safer.
    domains = [ "~." ];

    # Global DNS settings for Quad9 (IPv4 + IPv6)
    # The '#dns.quad9.net' part is for SNI/Certificate validation
    extraConfig = ''
      # Primary: Quad9
      # Secondary: Cloudflare & Mullvad (All with SNI cert validation)
      DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 1.1.1.1#one.one.one.one 194.242.2.2#dns.mullvad.net

      # Fallback: Only used if all above are unreachable
      FallbackDNS=9.9.9.10#dns.quad9.net 1.0.0.1#one.one.one.one

      Domains=~.
      LLMNR=no
      MulticastDNS=no
      # Only add this if you specifically saw .54 was missing and needed it:
      # DNSStubListenerExtra=127.0.0.54
    '';
  };

  ###
  ### Force everyhing to use local resolver
  ###
  # 5. Clean up resolv.conf
  # This creates the proper symlink so apps use the local resolved stub
  # resolved will manage /etc/resolv.conf automatically when enabled.
  networking.resolvconf.enable = false;


  ###
  ### Firewall
  ###
  # Even if a process tries to listen, the firewall will drop the packets.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # Only SSH
    allowedUDPPorts = [ ];   # Kill all incoming discovery (might kill chromecast)
  };
}
