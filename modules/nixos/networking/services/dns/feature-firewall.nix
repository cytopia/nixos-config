{
  config,
  lib,
  ...
}:
let
  cfg = config.cytopia.service.dns;
  fwCfg = cfg.firewall;

  # This group id is our dnscrypt-proxy, which should be allowed by the firewall
  proxyGid = toString cfg.internal.proxyGid;

  # Helper to append 'drop' if we are in block mode, otherwise just log
  actionRule = if fwCfg.mode == "block" then "drop" else "";
  actionRuleGoogle = if fwCfg.modeGoogleDoH == "block" then "drop" else "";
  actionRuleCloudflare = if fwCfg.modeCloudflareDoH == "block" then "drop" else "";
  actionRuleQuad9 = if fwCfg.modeQuad9DoH == "block" then "drop" else "";
  actionRuleNextDNS = if fwCfg.modeNextDNSDoH == "block" then "drop" else "";
  actionRuleOpenDNS = if fwCfg.modeOpenDNSDoH == "block" then "drop" else "";
  actionRuleAdGuard = if fwCfg.modeAdGuardDoH == "block" then "drop" else "";
  actionRuleCleanBrowsing = if fwCfg.modeCleanBrowsingDoH == "block" then "drop" else "";
  actionRuleMullvad = if fwCfg.modeMullvadDoH == "block" then "drop" else "";

  # Determine if we add Google/Cloudflare DoH
  addGoogle = fwCfg.modeGoogleDoH != "off";
  addCloudflare = fwCfg.modeCloudflareDoH != "off";
  addQuad9 = fwCfg.modeQuad9DoH != "off";
  addNextDNS = fwCfg.modeNextDNSDoH != "off";
  addOpenDNS = fwCfg.modeOpenDNSDoH != "off";
  addAdGuard = fwCfg.modeAdGuardDoH != "off";
  addCleanBrowsing = fwCfg.modeCleanBrowsingDoH != "off";
  addMullvad = fwCfg.modeMullvadDoH != "off";

  # IP ADDRESS Definitions
  ipsGoogleV4 = [ "8.8.8.8" "8.8.4.4" ];
  ipsGoogleV6 = [ "2001:4860:4860::8888" "2001:4860:4860::8844" ];

  ipsCloudflareV4 = [ "1.1.1.1" "1.0.0.1" "1.1.1.2" "1.0.0.2" "1.1.1.3" "1.0.0.3" ];
  ipsCloudflareV6 = [ "2606:4700:4700::1111" "2606:4700:4700::1001" "2606:4700:4700::1112" "2606:4700:4700::1002" "2606:4700:4700::1113" "2606:4700:4700::1003" ];

  ipsQuad9V4 = [ "9.9.9.9" "149.112.112.112" "9.9.9.10" "149.112.112.10" "9.9.9.11" "149.112.112.11" "9.9.9.12" "149.112.112.12" ];
  ipsQuad9V6 = [ "2620:fe::fe" "2620:fe::9" "2620:fe::10" "2620:fe::fe:10" "2620:fe::11" "2620:fe::fe:11" "2620:fe::12" "2620:fe::fe:12" ];

  ipsNextDNSV4 = [ "45.90.28.0" "45.90.30.0" ];
  ipsNextDNSV6 = [ "2a07:a8c0::" "2a07:a8c1::" ];

  ipsOpenDNSV4 = [ "208.67.222.222" "208.67.220.220" "208.67.222.123" "208.67.220.123" ];
  ipsOpenDNSV6 = [ "2620:119:35::35" "2620:119:53::53" "2620:119:35::123" "2620:119:53::123" ];

  ipsAdGuardV4 = [ "94.140.14.14" "94.140.15.15" "94.140.14.15" "94.140.15.16" "94.140.14.140" "94.140.14.141" ];
  ipsAdGuardV6 = [ "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff" "2a10:50c0::bad1:ff" "2a10:50c0::bad2:ff" "2a10:50c0::1:ff" "2a10:50c0::2:ff" ];

  ipsCleanBrowsingV4 = [ "185.228.168.9" "185.228.169.9" "185.228.168.10" "185.228.169.11" "185.228.168.168" "185.228.169.168" ];
  ipsCleanBrowsingV6 = [ "2a0d:2a00:1::2" "2a0d:2a00:2::2" "2a0d:2a00:1::1" "2a0d:2a00:2::1" "2a0d:2a00:1::" "2a0d:2a00:2::" ];

  ipsMullvadV4 = [ "194.242.2.2" "194.242.2.3" "194.242.2.4" "194.242.2.5" "194.242.2.9" ];
  ipsMullvadV6 = [ "2a07:e340::2" "2a07:e340::3" "2a07:e340::4" "2a07:e340::5" ];


in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  # We define the options right inside the feature file to keep it cohesive!
  options.cytopia.service.dns.firewall = {
    enable = lib.mkEnableOption "DNS leak prevention and rogue query interception";

    mode = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DNS traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
      '';
    };

    # Well-known DNS server
    modeGoogleDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeCloudflareDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeQuad9DoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeNextDNSDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeOpenDNSDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeAdGuardDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeCleanBrowsingDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
    modeMullvadDoH = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
        "off"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue DOH traffic (Current behavior).
        "block": Logs the traffic AND actively drops the packets.
        "off": Do not add firewall rule.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf (cfg.enable && fwCfg.enable) {

    networking.firewall.enable = true;
    networking.nftables.enable = true;

    networking.nftables.tables."dns-logging" = {
      family = "inet";
      content = ''
        ${lib.optionalString addGoogle ''
          set google_dns_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsGoogleV4} }; }
          set google_dns_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsGoogleV6} }; }
        ''}
        ${lib.optionalString addCloudflare ''
          set cf_dns_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsCloudflareV4} }; }
          set cf_dns_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsCloudflareV6} }; }
        ''}
        ${lib.optionalString addQuad9 ''
          set quad9_dns_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsQuad9V4} }; }
          set quad9_dns_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsQuad9V6} }; }
        ''}
        ${lib.optionalString addNextDNS ''
          set nextdns_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsNextDNSV4} }; }
          set nextdns_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsNextDNSV6} }; }
        ''}
        ${lib.optionalString addOpenDNS ''
          set opendns_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsOpenDNSV4} }; }
          set opendns_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsOpenDNSV6} }; }
        ''}
        ${lib.optionalString addAdGuard ''
          set adguard_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsAdGuardV4} }; }
          set adguard_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsAdGuardV6} }; }
        ''}
        ${lib.optionalString addCleanBrowsing ''
          set cleanbrowsing_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsCleanBrowsingV4} }; }
          set cleanbrowsing_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsCleanBrowsingV6} }; }
        ''}
        ${lib.optionalString addMullvad ''
          set mullvad_v4 { type ipv4_addr; elements = { ${builtins.concatStringsSep ", " ipsMullvadV4} }; }
          set mullvad_v6 { type ipv6_addr; elements = { ${builtins.concatStringsSep ", " ipsMullvadV6} }; }
        ''}

        chain output {
          type filter hook output priority -10; policy accept;

          # LOG/BLOCK Rogue outbound DNS (Port 53 & 853 DoT)
          oifname != "lo" meta skgid != ${proxyGid} meta l4proto { tcp, udp } th dport 53 log prefix "[DNS-Leak-Rogue] " ${actionRule}
          oifname != "lo" meta skgid != ${proxyGid} meta l4proto { tcp, udp } th dport 853 log prefix "[DNS-Leak-DoT] " ${actionRule}

          # LOG/BLOCK DoH/DNSCrypt ports (443 & 8443) of well-known DNS server
          ${lib.optionalString addGoogle ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @google_dns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Google] " ${actionRuleGoogle}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @google_dns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Google] " ${actionRuleGoogle}
          ''}
          ${lib.optionalString addCloudflare ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @cf_dns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Cloudflare] " ${actionRuleCloudflare}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @cf_dns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Cloudflare] " ${actionRuleCloudflare}
          ''}
          ${lib.optionalString addQuad9 ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @quad9_dns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Quad9] " ${actionRuleQuad9}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @quad9_dns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Quad9] " ${actionRuleQuad9}
          ''}
          ${lib.optionalString addNextDNS ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @nextdns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-NextDNS] " ${actionRuleNextDNS}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @nextdns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-NextDNS] " ${actionRuleNextDNS}
          ''}
          ${lib.optionalString addOpenDNS ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @opendns_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-OpenDNS] " ${actionRuleOpenDNS}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @opendns_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-OpenDNS] " ${actionRuleOpenDNS}
          ''}
          ${lib.optionalString addAdGuard ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @adguard_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-AdGuard] " ${actionRuleAdGuard}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @adguard_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-AdGuard] " ${actionRuleAdGuard}
          ''}
          ${lib.optionalString addCleanBrowsing ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @cleanbrowsing_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-CleanBrowsing] " ${actionRuleCleanBrowsing}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @cleanbrowsing_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-CleanBrowsing] " ${actionRuleCleanBrowsing}
          ''}
          ${lib.optionalString addMullvad ''
            oifname != "lo" meta skgid != ${proxyGid} ip daddr @mullvad_v4 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Mullvad] " ${actionRuleMullvad}
            oifname != "lo" meta skgid != ${proxyGid} ip6 daddr @mullvad_v6 meta l4proto { tcp, udp } th dport { 443, 8443 } log prefix "[DNS-Leak-DoH|Crypt-Mullvad] " ${actionRuleMullvad}
          ''}
        }
      '';
    };
  };
}
