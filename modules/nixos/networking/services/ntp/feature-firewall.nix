{
  config,
  lib,
  ...
}:

let
  # Adjust this path if you place it elsewhere
  cfg = config.cytopia.service.ntp;
  ntpCfg = cfg.firewall;

  # Helper to append 'drop' if we are in block mode, otherwise just log
  actionRule = if ntpCfg.mode == "block" then "drop" else "";

  # The "Nix Way": Dynamically fetch NixOS's official static Chrony UID (61)
  # Using the integer bypasses the nftables build-sandbox username lookup crash.
  chronyUid = toString config.ids.uids.chrony;
in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  options.cytopia.service.ntp.firewall = {
    enable = lib.mkEnableOption "NTP leak prevention and rogue query interception";

    mode = lib.mkOption {
      type = lib.types.enum [
        "log"
        "block"
      ];
      default = "log";
      description = ''
        "log": Passively monitors and logs rogue NTP traffic.
        "block": Logs the traffic AND actively drops the packets.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf (cfg.enable && ntpCfg.enable) {

    networking.firewall.enable = true;
    networking.nftables.enable = true;

    networking.nftables.tables."ntp-logging" = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority -10; policy accept;

          # LOG/BLOCK Rogue outbound NTP (UDP 123)
          # If the traffic is headed for port 123, but the process owner is NOT the 'chrony' user, drop it.
          oifname != "lo" meta skuid != ${chronyUid} udp dport 123 log prefix "[NTP-Leak-Rogue] " ${actionRule}

          # LOG/BLOCK Rogue outbound NTS-KE (TCP 4460)
          # Prevents other applications from establishing rogue Network Time Security sessions.
          oifname != "lo" meta skuid != ${chronyUid} tcp dport 4460 log prefix "[NTS-Leak-Rogue] " ${actionRule}

          # (Optional) LOG/BLOCK Rogue outbound Chrony Command Port (UDP 323)
          # Only relevant if you have misconfigured chrony, but good for defense-in-depth.
          oifname != "lo" meta skuid != ${chronyUid} udp dport 323 log prefix "[Time-Leak-Cmd] " ${actionRule}

          # (Optional) LOG/BLOCK Rogue outbound PTP (Precision Time Protocol)
          oifname != "lo" meta skuid != ${chronyUid} udp dport { 319, 320 } log prefix "[PTP-Leak-Rogue] " ${actionRule}
        }
      '';
    };
  };
}
