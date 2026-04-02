{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.networking.service.ntp;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.networking.service.ntp = {
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

    # Hardcode NTS time servers to break the Time/DNS deadlock
    networking.extraHosts = ''
      # Cloudflare NTS (Anycast)
      162.159.200.1 time.cloudflare.com
      2606:4700:f1::1 time.cloudflare.com

      # Netnod NTS (Anycast)
      194.58.207.79 nts.netnod.se
      2a01:3f0:1:4::28 nts.netnod.se

      # TimeNL NTS (Anycast - Dutch Non-Profit, High Privacy)
      94.198.159.11 nts.time.nl
      2a00:d78:0:712:94:198:159:11 nts.time.nl

      # PTB Germany (Unicast - Ultimate Precision for DE)
      192.53.103.108 ptbtime1.ptb.de
      2001:638:610:be01::108 ptbtime1.ptb.de
    '';

    # Use NTS (Network Time Security) via chrony.
    # Provides secure, encrypted time sync over SSL.
    services.chrony = {
      enable = true;
      servers = [ ]; # Clear defaults and use extraConfig

      extraConfig = ''
        # 1. UPSTREAM SERVERS
        # Use NTS (Network Time Security) for encrypted time sync
        server time.cloudflare.com iburst nts
        server nts.netnod.se iburst nts
        server nts.time.nl iburst nts
        server ptbtime1.ptb.de iburst nts

        # 2. BOOTSTRAP FIXES
        # # Ignore NTS cert expiration for the first sync, even if time is years off
        nocerttimecheck 1
        # Sync clock immediately if offset > 1s during the first 3 updates
        makestep 1 3

        # 3. SECURITY: STRICT CLIENT MODE
        # Disable NTP server (UDP 123)
        port 0
        # Disable remote chronyc (UDP 323)
        cmdport 0
        #bindcmdaddress 127.0.0.1
        #bindcmdaddress ::1
      '';
    };
  };
}
