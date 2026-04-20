{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security.attackSurface;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security.attackSurface = {

            disablePasswordManager = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hardens the local browser profile by disabling the built-in Chrome password manager
                and passkeys. Guarantees malware cannot extract credentials from local SQLite databases.
              '';
            };

            disableAutofill = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hardens the local browser profile by disabling form autofill for addresses
                and credit cards. Prevents malicious scripts from triggering hidden autofills.
              '';
            };

            disableBrowserLabs = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Turns off experimental Chrome features (Browser Labs/chrome://flags) that lack full security audits.
              '';
            };

            disablePwaInstallation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly prevents the installation of Progressive Web Apps (PWAs) by the user,
                reducing persistent local attack surfaces.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disablePasswordManager {
                "PasswordManagerEnabled" = false;
                "PasswordManagerPasskeysEnabled" = false;
                "AutomatedPasswordChangeSettings" = 0;
                "DeletingUndecryptablePasswordsEnabled" = false;
                "PasswordManagerBlocklist" = [ "*" ];
              })

              (lib.mkIf cfg.disableAutofill {
                "AutofillAddressEnabled" = false;
                "AutofillCreditCardEnabled" = false;
              })

              (lib.mkIf cfg.disableBrowserLabs {
                # Disables the "chrome://flags" experiments and Browser Labs.
                "BrowserLabsEnabled" = false;
              })

              (lib.mkIf cfg.disablePwaInstallation {
                # Prevents websites from installing Progressive Web Apps to the OS.
                "WebAppInstallByUserEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
