{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security.systemIntegration;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security.systemIntegration = {

            disableOsKeyring = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Severs integration with the host OS keyring (GNOME Keyring/KWallet).
                Forces Chrome to use a dummy basic password store to prevent dbus exploits.
              '';
            };

            disableRemoteAccess = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Completely disables Chrome Remote Desktop connections, remote firewall
                traversal, and remote developer debugging ports. Severs external takeover vectors.
              '';
            };

            strictExternalProtocols = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Prevents users from checking the "Always allow" box when a website tries
                to open an external application (like Zoom or xdg-open). Forces a security
                prompt every single time to prevent drive-by execution. Also forces PDFs to
                open in the internal sandboxed reader instead of a vulnerable external app.
              '';
            };

            blockExternalExtensions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Prevents external software on your OS from silently side-loading
                browser extensions into your profile without your consent.
              '';
            };

            disableBackgroundMode = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly prevents Chrome from silently running background processes, apps,
                or extensions after the last visible browser window is explicitly closed.
              '';
            };

            enforceSecurityWarnings = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Ensures the browser displays a prominent warning banner if it was
                launched with dangerously degraded command-line flags (like --disable-web-security).
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.flags = lib.mkMerge [
              (lib.optionals cfg.disableOsKeyring [
                # Mapped precisely to the new disableOsKeyring option
                "--password-store=basic"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableBackgroundMode {
                "BackgroundModeEnabled" = false;
              })

              (lib.mkIf cfg.disableRemoteAccess {
                "RemoteAccessHostAllowRemoteAccessConnections" = false;
                "RemoteAccessHostFirewallTraversal" = false;
                "RemoteDebuggingAllowed" = false;
              })

              (lib.mkIf cfg.strictExternalProtocols {
                "ExternalProtocolDialogShowAlwaysOpenCheckbox" = false;
                "AlwaysOpenPdfExternally" = false;
              })

              (lib.mkIf cfg.blockExternalExtensions {
                "BlockExternalExtensions" = true;
              })

              (lib.mkIf cfg.enforceSecurityWarnings {
                "CommandLineFlagSecurityWarningsEnabled" = true;
              })
            ];
          };
        }
      )
    );
  };
}
