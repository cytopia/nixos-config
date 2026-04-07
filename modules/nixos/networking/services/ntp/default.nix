{
  config,
  lib,
  ...
}:

let
  cfg = config.cytopia.service.ntp;
in
{
  imports = [
    ./feature-firewall.nix # Optional
  ];

  ###
  ### 1. OPTIONS
  ###
  options.cytopia.service.ntp = {
    enable = lib.mkEnableOption "Chrony NTP server";
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # What: Disable default unencrypted NTP.
    # How: Clears timeservers and disables timesyncd.
    # Why: Stops plaintext UDP 123 leaks.
    networking.timeServers = [ ];
    services.timesyncd.enable = false;

    # Hardcode static, unicast NTS time servers to break the Time/DNS deadlock.
    networking.extraHosts = /* bash */ ''
      # PTB Germany (Unicast - High Privacy, National Atomic Clock)
      192.53.103.108 ptbtime1.ptb.de
      2001:638:610:be01::108 ptbtime1.ptb.de

      192.53.103.104 ptbtime2.ptb.de
      2001:638:610:be01::104 ptbtime2.ptb.de

      192.53.103.103 ptbtime3.ptb.de
      2001:638:610:be01::103 ptbtime3.ptb.de

      # FAU Erlangen-Nürnberg (Unicast - Strict Privacy Academic Server)
      131.188.3.223 ntp3.fau.de
      2001:638:a000:1123:131:188:3:223 ntp3.fau.de

      # Netnod (Sweden - NGO Infrastructure, Unicast Nodes)
      194.58.207.69 sth1.nts.netnod.se
      2a01:3f0:0:305::2 sth1.nts.netnod.se

      194.58.207.74 sth2.nts.netnod.se
      2a01:3f0:0:306::2 sth2.nts.netnod.se
    '';

    # Use NTS (Network Time Security) via chrony.
    # Provides secure, encrypted time sync over SSL.
    services.chrony = {
      enable = true;
      servers = [ ]; # Clear defaults and use extraConfig

      extraConfig = /* bash */ ''
        # ==========================================================
        # 1. UPSTREAM SERVERS
        # ==========================================================
        # Rely exclusively on hardcoded NTS servers.
        # iburst: Send a burst of 8 packets quickly on boot to speed up initial sync.
        server ptbtime1.ptb.de iburst nts
        server ptbtime2.ptb.de iburst nts
        server ptbtime3.ptb.de iburst nts

        server ntp3.fau.de iburst nts

        server sth1.nts.netnod.se iburst nts
        server sth2.nts.netnod.se iburst nts

        # ==========================================================
        # 2. BOOTSTRAP FIXES & DEADLOCK RESOLUTION
        # ==========================================================
        # CHICKEN-AND-EGG PROBLEM:
        # dnscrypt-proxy requires an accurate clock to validate DNS servers TLS certificates.
        # However, chrony requires DNS to resolve upstream NTS time servers.
        #
        # SOLUTION:
        # We break this deadlock by hardcoding a select few static, unicast NTS servers
        # in /etc/hosts. Chrony connects to these IPs directly on boot.

        # MITIGATION A: TLS Expiration Bypass
        # Because the local system clock might be completely wrong (e.g., dead RTC battery),
        # the TLS certificate presented by the NTS server during the Key Establishment
        # handshake will appear expired or not-yet-valid. This setting forces chrony to
        # ignore the certificate's time constraints for the first successful sync.
        nocerttimecheck 1

        # MITIGATION B: Infinite Clock Stepping (The Sleep/Wake/VM Fix)
        # Syntax: makestep <threshold-in-seconds> <limit>
        # By default, chrony smoothly "slews" the clock to correct time drift. If the
        # offset is massive, slewing could take weeks.
        #
        # 'makestep 1 -1' tells chrony: "If the time is off by more than 1 second, snap
        # (step) the clock immediately. Do this indefinitely (-1)."
        #
        # Why '-1' is critical: If a laptop goes to sleep or a VM is paused, the clock
        # stops. Upon waking, the system time will instantly jump forward by hours.
        # If a limit is set (e.g., '1 3'), chrony will refuse to step the clock after
        # the first 3 updates, causing NTS to permanently fail and drop all sources
        # with "Forward time jump detected!" errors.
        makestep 1 -1

        # ==========================================================
        # 3. SECURITY: STRICT CLIENT MODE
        # ==========================================================
        # Disable NTP server (UDP 123)
        port 0
        # Disable remote chronyc (UDP 323)
        cmdport 0
      '';
    };
  };
}
