{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.privacy.localState;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy.localState = {

            forceBlankNewTabPage = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces about:blank on new tabs to prevent leaking recently visited pages
                or search history thumbnails to shoulder surfers or local background scripts.
              '';
            };

            limitDataRetention = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces strict local data retention limits.
                Ensures local user data snapshots are not retained or hoarded indefinitely.
              '';
            };

            disableLocalDataScraping = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Stops the browser from scraping bookmarks and history from other browsers
                on your hard drive during the first run.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.forceBlankNewTabPage {
                # Enforces about:blank on new tabs to prevent leaking recently visited pages.
                "NewTabPageLocation" = "about:blank";
              })

              (lib.mkIf cfg.limitDataRetention {
                # Limits the retention of user data snapshots to prevent local/synced storage hoarding.
                "UserDataSnapshotRetentionLimit" = 0;
              })
            ];

            internal.initialPreferences = lib.mkMerge [
              (lib.mkIf cfg.disableLocalDataScraping {
                "distribution" = {
                  "import_bookmarks" = false;
                  "import_history" = false;
                };
              })
            ];
          };
        }
      )
    );
  };
}
