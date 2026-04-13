{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security.tls;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security.tls = {

            forceStrictTls = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks mixed insecure (HTTP) content on secure pages.
                Additionally, it explicitly routes the TLS pre-master secret log to /dev/null,
                ensuring rogue Wayland processes cannot dump and decrypt your secure HTTPS web traffic.
              '';
            };

            preventSslBypass = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Removes the "Proceed anyway" button from SSL/TLS warning pages.
                Forces the browser to strictly drop connections to invalid certificates.
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.forceStrictTls {
                # Points the SSL key dump explicitly to /dev/null.
                "SSLKEYLOGFILE" = "/dev/null";
              })
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.preventSslBypass {
                # Disables the ability for a user to click through certificate errors.
                "SSLErrorOverrideAllowed" = false;
              })

              (lib.mkIf cfg.forceStrictTls {
                # A value of 2 strictly blocks loading HTTP content on an HTTPS page.
                "DefaultInsecureContentSetting" = 2;
              })

            ];
          };
        }
      )
    );
  };
}
