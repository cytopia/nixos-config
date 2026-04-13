{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.privacy.identity;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy.identity = {

            disableBrowserSync = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Explicitly disables browser sign-in and stops background account token generation.
                Disables Google Sync for passwords, bookmarks, history, and settings to prevent
                your local data from being uploaded to a centralized server.
              '';
            };

            blockFederatedLogins = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Blocks federated login prompts (like "Sign in with Google") to prevent
                identity tracking across third-party domains.
              '';
            };

            disableGoogleEcosystem = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables Google ecosystem integrations that leak local state or link accounts.
                Kills "Click to Call" (sending numbers to your phone), Family password sharing,
                cloud-synced shopping carts, and Developer Tools profile linking.
              '';
            };

            hardKillApis = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hard-blocks Google API services by injecting invalid API keys into the environment.
                Acts as a kill-switch. Even if telemetry policies fail, Chrome's requests to Google's backend
                will be rejected with an authentication error.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.hardKillApis {
                # Injects invalid credentials to act as a hard kill-switch for Google APIs.
                # Forces backend services to reject Chrome's requests entirely.
                "GOOGLE_API_KEY" = "no";
                "GOOGLE_DEFAULT_CLIENT_ID" = "no";
                "GOOGLE_DEFAULT_CLIENT_SECRET" = "no";
              })
            ];

            internal.disableFeatures = lib.mkMerge [
              (lib.optionals cfg.blockFederatedLogins [
                # Blocks the Federated Credential Management API (FedCm).
                # Stops intrusive third-party identity prompts from tracking activity.
                "FedCm"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableBrowserSync {
                # A value of 0 explicitly disables browser sign-in and background token generation.
                "BrowserSignin" = 0;
                "SyncDisabled" = true;
                "BrowserAddPersonEnabled" = false;
                "BrowserGuestModeEnabled" = false;
              })

              (lib.mkIf cfg.disableGoogleEcosystem {
                # Disables "Click to Call" sending phone numbers to your Android device.
                "ClickToCallEnabled" = false;
                # Stops Developer Tools from linking to a Google Developer Profile.
                "DevToolsGoogleDeveloperProgramProfileAvailability" = 2;
                # Disables sharing passwords with a Google Family group.
                "PasswordSharingEnabled" = false;
                # Kills the built-in price tracking and cloud-synced shopping cart features.
                "ShoppingListEnabled" = false;
              })
            ];

            internal.initialPreferences = lib.mkMerge [
              (lib.mkIf cfg.blockFederatedLogins {
                # Blocks intrusive "Sign in with Google/Facebook" slide-down prompts on all websites (*,*).
                # These prompts are a privacy risk because they allow identity providers to track
                # your browsing habits across different, unrelated third-party domains.
                # Injecting 'setting = 2' (Block) into the initial preferences guarantees this
                # tracking API is dead on arrival the very first time you open the browser.
                "profile" = {
                  "content_settings" = {
                    "exceptions" = {
                      "federated-identity-api" = {
                        "*,*" = {
                          "setting" = 2;
                        };
                      };
                    };
                  };
                };
              })
            ];
          };
        }
      )
    );
  };
}
