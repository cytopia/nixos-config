{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.certificates;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.certificates = {

            customCaCerts = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    name = lib.mkOption {
                      type = lib.types.str;
                      description = "Unique name for the cert. Used in the NSS database alias.";
                    };
                    path = lib.mkOption {
                      type = lib.types.str;
                      description = "Full path to the .pem file to watch and inject.";
                    };
                  };
                }
              );
              default = [ ];
              description = ''
                List of CA certificates to dynamically sync with the browser's NSS database.
                NixOS will create a background systemd user service that watches these file paths.
                The moment a certificate is created or updated, it is instantly injected.
                If removed from this list, a cleanup service will purge it from the database.
              '';
            };
          };
        }
      )
    );
  };

  config =
    let
      # 1. Flatten all customCaCerts from all browsers into a single list
      allCerts = lib.flatten (
        lib.mapAttrsToList (
          name: browserCfg: browserCfg.features.certificates.customCaCerts
        ) config.cytopia.programs.browsers
      );

      # 2. Make the list unique by name to avoid duplicate systemd services
      uniqueCerts = lib.unique allCerts;

      # 3. Generate a space-separated string of currently active NixOS aliases
      activeNicknames = map (cert: "NixOS-Managed-${cert.name}") uniqueCerts;
      activeNicknamesStr = lib.concatStringsSep " " activeNicknames;
    in
    {
      # --- LIVE WATCHERS (Only created if there are actually certs to watch) ---
      systemd.user.paths = lib.mkIf (builtins.length uniqueCerts > 0) (
        lib.mkMerge (
          map (cert: {
            "sync-nssdb-${cert.name}" = {
              wantedBy = [ "default.target" ];
              description = "Watch for changes to ${cert.name} CA certificate";
              pathConfig = {
                PathChanged = cert.path;
              };
            };
          }) uniqueCerts
        )
      );

      # --- INJECTION SERVICES AND GLOBAL CLEANUP ---
      systemd.user.services = lib.mkMerge [

        # A. The Injection Services (Only created if certs exist)
        (lib.mkIf (builtins.length uniqueCerts > 0) (
          lib.mkMerge (
            map (cert: {
              "sync-nssdb-${cert.name}" = {
                description = "Inject ${cert.name} CA into Browser NSSDB";
                wantedBy = [ "default.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = pkgs.writeShellScript "sync-nssdb-${cert.name}" ''
                    NSSDB="$HOME/.pki/nssdb"
                    CERT="${cert.path}"
                    NSSBIN="${pkgs.nssTools}/bin/certutil"
                    ALIAS="NixOS-Managed-${cert.name}"

                    # 1. DATABASE INITIALIZATION
                    # If the NSS database directory doesn't exist (e.g., brand new user profile),
                    # we need to create the directory and initialize an empty database.
                    if [ ! -d "$NSSDB" ]; then
                      echo "Initializing empty database"
                      mkdir -p "$NSSDB"

                      # [NSSBIN COMMAND EXPLANATION]: Initialize Database
                      # $NSSBIN           : Calls the 'certutil' binary.
                      # -d sql:$NSSDB     : Specifies the database directory, telling it to use the modern SQLite format ('sql:').
                      # -N                : Tells certutil to create a New database.
                      # --empty-password  : Initializes the database with no master password so it doesn't prompt the user.
                      # 2>/dev/null       : Discards any non-critical error messages to keep the systemd logs clean.
                      $NSSBIN -d sql:$NSSDB -N --empty-password 2>/dev/null
                    fi

                    # 2. MISSING FILE HANDLING (WITH DEBOUNCE)
                    # Handle the scenario where the physical file is gone (e.g., dnscrypt-proxy disabled DoH,
                    # or the daemon is just temporarily restarting).
                    if [ ! -f "$CERT" ]; then
                      # Pause execution for 2 seconds before reacting. This acts as a debounce
                      # to prevent ripping the cert out of running browsers during a quick daemon restart.
                      echo "$CERT not found, waiting 2 seconds..."
                      sleep 2
                      # Check a second time. If the file is STILL missing after 2 seconds,
                      # it was a genuine deletion, not a temporary restart glitch.
                      if [ ! -f "$CERT" ]; then
                        # [NSSBIN COMMAND EXPLANATION]: Delete Certificate
                        # -d sql:$NSSDB : Target the user's NSS database.
                        # -D            : Delete a certificate.
                        # -n "$ALIAS"   : Delete the specific certificate that matches this nickname.
                        # || true       : If the cert isn't in the DB to begin with, certutil throws an error.
                        #                 This catches the error so the script exits successfully (code 0).
                        echo "$CERT still not found, deleting '$ALIAS' from NSSDB..."
                        $NSSBIN -d sql:$NSSDB -D -n "$ALIAS" 2>/dev/null || true

                        # Exit the script, as the certificate is gone and after DB deletion we exit
                        exit 0
                      fi
                    fi
                    # Delete cert in case it is old/changed/expired
                    echo "Deleting cert '$ALIAS' from NSSDB"
                    $NSSBIN -d sql:$NSSDB -D -n "$ALIAS" 2>/dev/null || true
                    # Add & Trust Certificate
                    echo "ReAdding cert '$ALIAS' to NSSDB"
                    $NSSBIN -d sql:$NSSDB -A -t "CT,C,C" -n "$ALIAS" -i "$CERT"
                  '';
                };
              };
            }) uniqueCerts
          )
        ))

        # B. The Global Cleanup Service (ALWAYS created)
        # This guarantees orphaned certs are nuked even if you empty the NixOS config list.
        {
          "cleanup-nssdb-certs" = {
            description = "Clean up orphaned NixOS-managed CA certificates from NSSDB";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "cleanup-nssdb-certs" ''
                NSSDB="$HOME/.pki/nssdb"
                NSSBIN="${pkgs.nssTools}/bin/certutil"
                ACTIVE_CERTS="${activeNicknamesStr}"

                # If DB doesn't exist, there is nothing to clean
                if [ ! -d "$NSSDB" ]; then
                  exit 0
                fi

                # List all certs, filter by our NixOS prefix, extract the nickname
                $NSSBIN -d sql:$NSSDB -L 2>/dev/null | grep "NixOS-Managed-" | while read -r line; do
                  # Strip trailing spaces and trust flags to get the raw nickname
                  nickname=$(echo "$line" | sed 's/ \{2,\}.*//; s/[[:space:]]*$//')

                  # Check if this database nickname exists in our active NixOS config
                  is_active=false
                  for active in $ACTIVE_CERTS; do
                    if [ "$nickname" = "$active" ]; then
                      is_active=true
                      break
                    fi
                  done

                  # If it's not in the config, it's an orphan. Purge it.
                  if [ "$is_active" = false ]; then
                    echo "Purging orphaned certificate: $nickname"
                    $NSSBIN -d sql:$NSSDB -D -n "$nickname" 2>/dev/null || true
                  fi
                done
              '';
            };
          };
        }
      ];
    };
}
