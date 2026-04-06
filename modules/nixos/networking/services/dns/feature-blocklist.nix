{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cytopia.service.dns;

  # Check if we actually have URLs so we don't run an empty curl command]
  hasUrls = builtins.length cfg.localBlockList.urls > 0;
in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  options.cytopia.service.dns = {
    localBlockList = {
      enable = lib.mkEnableOption "Enable block list";
      urls = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Specify an URL to download a blocklist.";
      };
    };
    whitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "A list of domains to strictly allow, bypassing all blocklists.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkMerge [

    # 1. Whitelist
    (lib.mkIf (cfg.enable && cfg.localBlockList.enable && (builtins.length cfg.whitelist > 0)) {
      services.dnscrypt-proxy.settings.allowed_names = {
        allowed_names_file = "${pkgs.writeText "allowed-names.txt" (
          builtins.concatStringsSep "\n" cfg.whitelist
        )}";
        log_file = "/var/lib/dnscrypt-proxy/allowed-names.log";
        log_format = "tsv";
      };
    })

    # 2. Blocklist file
    (lib.mkIf (cfg.enable && cfg.localBlockList.enable) {
      services.dnscrypt-proxy.settings.blocked_names = {
        blocked_names_file = "/var/lib/dnscrypt-proxy/blocked-names.txt";
        log_file = "/var/lib/dnscrypt-proxy/blocked-names.log";
        log_format = "tsv";
      };

      # 2. Pre-Start Bootstrap
      # NixOS will automatically concatenate this with any other preStart scripts
      # defined in your other feature files!
      systemd.services.dnscrypt-proxy.preStart = ''
        # =================================================================
        # BOOTSTRAP BLOCKLIST (Fixes the "File Not Found" crash on first boot)
        # =================================================================
        if [ ! -f "/var/lib/dnscrypt-proxy/blocked-names.txt" ]; then
          echo "Bootstrapping empty blocklist..."
          touch "/var/lib/dnscrypt-proxy/blocked-names.txt"
          chgrp dnscrypt "/var/lib/dnscrypt-proxy/blocked-names.txt"
          chmod 664 "/var/lib/dnscrypt-proxy/blocked-names.txt"
        fi
      '';

      # 3. The Downloader Service
      # Wrapped in lib.mkIf hasUrls to prevent execution if no URLs are provided]
      systemd.services.dnscrypt-proxy-update-blocklist = lib.mkIf hasUrls {
        description = "Download fresh OISD blocklist for dnscrypt-proxy";

        # Added dnscrypt-proxy.service to requires/after so we are guaranteed
        # the StateDirectory has been created by the main proxy first]
        requires = [ "dnscrypt-proxy.service" ];
        after = [
          "network-online.target"
          "dnscrypt-proxy.service"
        ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              safeUrls = lib.concatStringsSep " " (map lib.escapeShellArg cfg.localBlockList.urls);
              downloadScript = pkgs.writeShellScript "update-blocklists.sh" ''
                ${pkgs.curl}/bin/curl -sSL ${safeUrls} > /var/lib/dnscrypt-proxy/blocked-names.txt
              '';
            in
            "${downloadScript}";

          ExecStartPost = [
            "${pkgs.coreutils}/bin/chgrp dnscrypt /var/lib/dnscrypt-proxy/blocked-names.txt"
            "${pkgs.coreutils}/bin/chmod 664 /var/lib/dnscrypt-proxy/blocked-names.txt"
            "+-${pkgs.procps}/bin/pkill -HUP dnscrypt-proxy"
          ];

          # Removed DynamicUser and StateDirectory. Replaced with native User.
          # This prevents systemd from chown-ing the directory and stealing it from the main proxy]
          DynamicUser = true;
          Group = "dnscrypt";
          StateDirectory = "dnscrypt-proxy";
          StateDirectoryMode = "0775";
        };
      };

      # 4. The Timer
      # Wrapped in lib.mkIf hasUrls to prevent the timer from firing if no URLs are provided]
      systemd.timers.dnscrypt-proxy-update-blocklist = lib.mkIf hasUrls {
        description = "Run OISD update weekly";
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };
    })
  ];
}
