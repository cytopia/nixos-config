{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cytopia.service.dns;

  # The central trigger: Do we need certificates?
  needsCerts = cfg.localDoh.enable || cfg.localMonitoring.enable;

  # Extract the directory name for the RAM-backed tmpfs
  caDir = builtins.dirOf cfg.certs.caCertPath;
  caDirName = builtins.baseNameOf caDir;
in
{
  ###
  ### 1. FEATURE OPTIONS
  ###
  options.cytopia.service.dns.certs = {
    caCertPath = lib.mkOption {
      type = lib.types.str; # We use string so Nix doesn't evaluate it as a build-time path
      default = "/run/local-doh-ca/rootCA.pem";
      description = ''
        The full path where the public Root CA will be exposed to.
        It MUST be a subdirectory of /run/ (e.g., /run/custom-dir/cert.pem)
        so systemd can automatically create the temporary RuntimeDirectory.
        Use this path to import it into your browser for DoH or Monitoring.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkMerge [

    # #####################################################################
    # ACTIVE STATE: GENERATE & SERVE CERTS
    # #####################################################################
    (lib.mkIf (cfg.enable && needsCerts) {

      # Validate the shared CA path
      assertions = [
        {
          assertion = lib.hasPrefix "/run/" cfg.certs.caCertPath;
          message = ''
            [DNS Module Error]: 'certs.caCertPath' MUST start with '/run/'.
            Current value is: ${cfg.certs.caCertPath}
          '';
        }
        {
          # If path is /run/rootCA.pem, caDir is /run. Systemd would try to create /run/run.
          assertion = caDir != "/run";
          message = ''
            [DNS Module Error]: 'certs.caCertPath' MUST be placed inside a subdirectory of /run/.
            Do not place it directly in /run/.
            Example of a good path: /run/my-certs/rootCA.pem
          '';
        }
      ];

      # Tell systemd to create the RAM-backed directory
      systemd.services.dnscrypt-proxy.serviceConfig = {
      # =====================================================================================
      # SYSTEMD RUNTIME DIRECTORY EXPLANATION
      # =====================================================================================
      # 1. Why RuntimeDirectory and why copy it every reboot?
      # The private keys and actual certificates live persistently in `/var/lib/dnscrypt-proxy/certs`.
      # For security, that directory is highly restricted (owned solely by the dnscrypt user).
      # However, your browser running as your standard desktop user needs to read the public
      # *Root CA* to trust the local DoH server.
      # `RuntimeDirectory` tells systemd to dynamically create folders inside `/run`. Because
      # `/run` is a `tmpfs` (a temporary filesystem in RAM), it gets completely wiped every
      # time the computer powers down. When you boot up, systemd creates the empty folder,
      # and our `preStart` script automatically copies the public cert into it. This gives us
      # a safe, temporary place to expose the public cert without compromising the strict
      # file permissions of the persistent `/var` directory.

      # 2. Why do we include "dnscrypt-proxy" in the string?
      # As per troubleshooting, the "dnscrypt-proxy" directory was empty and unused by the
      # daemon. We removed it to reduce clutter. The comment below is preserved for history.]
      # `RuntimeDirectory` accepts a space-separated list of folders. By default, the upstream
      # NixOS module for dnscrypt-proxy expects `/run/dnscrypt-proxy` to exist...
      #
      # 3. Why lib.mkForce?
      # Re-added lib.mkForce. The upstream NixOS dnscrypt-proxy module defines
      # RuntimeDirectory="dnscrypt-proxy". Without mkForce, Nix will throw a collision error.]
      # In the NixOS module system, if two different files try to define the exact same
      # `serviceConfig` string, NixOS doesn't combine them...
      #TODO: Come back to this and check with Gemini: https://gemini.google.com/app/cd54190755a4c523
      RuntimeDirectory = lib.mkForce caDirName;

      # Why RuntimeDirectoryMode = "0755"?
      #   This ensures that your regular desktop user (Firefox/Chrome) is
      #   allowed to navigate into `/run/local-doh-ca/` and read the `rootCA.pem` file.
      RuntimeDirectoryMode = "0755";
      };

      # The Generation Script
      systemd.services.dnscrypt-proxy.preStart = ''
        # =================================================================
        # GENERATE LOCAL CERTIFICATES (DoH & Monitoring)
        # =================================================================
        CERT_DIR="/var/lib/dnscrypt-proxy/certs"
        mkdir -p "$CERT_DIR"
        chgrp dnscrypt "$CERT_DIR"
        chmod 750 "$CERT_DIR"

        export CAROOT="$CERT_DIR"

        # A. Generate Custom Root CA
        if [ ! -f "$CERT_DIR/rootCA.pem" ] || [ ! -f "$CERT_DIR/rootCA-key.pem" ]; then
          echo "Generating Custom Root CA with OpenSSL..."
          ${pkgs.openssl}/bin/openssl genrsa -out "$CERT_DIR/rootCA-key.pem" 3072
          chmod 600 "$CERT_DIR/rootCA-key.pem"
          ${pkgs.openssl}/bin/openssl req -x509 -new -nodes -key "$CERT_DIR/rootCA-key.pem" \
            -sha256 -days 3650 -out "$CERT_DIR/rootCA.pem" \
            -subj "/O=dnscrypt-proxy listener for local DoH/CN=(localhost) dnscrypt-proxy" \
            -addext "basicConstraints=critical,CA:TRUE" \
            -addext "keyUsage=critical,keyCertSign,cRLSign"
        fi

        # B. Generate Localhost Leaf Certificate
        if [ ! -f "$CERT_DIR/localhost.pem" ] || [ ! -f "$CERT_DIR/localhost-key.pem" ]; then
          echo "Generating local certificates using mkcert..."
          ${pkgs.mkcert}/bin/mkcert -install
          ${pkgs.mkcert}/bin/mkcert -cert-file "$CERT_DIR/localhost.pem" \
                                    -key-file "$CERT_DIR/localhost-key.pem" \
                                    localhost 127.0.0.1 ::1

          chmod 644 "$CERT_DIR/localhost.pem"
          chmod 640 "$CERT_DIR/localhost-key.pem"
          chgrp dnscrypt "$CERT_DIR/localhost-key.pem"
        fi

        # C. Expose the public Root CA via the RAM-backed RuntimeDirectory
        cp "$CERT_DIR/rootCA.pem" "${cfg.certs.caCertPath}"
        chmod 644 "${cfg.certs.caCertPath}"
      '';
    })

    # #####################################################################
    # CLEANUP STATE: SCRUB ORPHANED CERTS
    # #####################################################################
    (lib.mkIf (!cfg.enable || !needsCerts) {
      system.activationScripts.cleanupDnscryptCerts = {
        text = ''
          CERT_DIR="/var/lib/dnscrypt-proxy/certs"
          if [ -d "$CERT_DIR" ]; then
            echo "[DNS Module] Local DoH & Monitoring disabled. Scrubbing orphaned certificates..."
            rm -rf "$CERT_DIR"
          fi
        '';
      };
    })
  ];
}
