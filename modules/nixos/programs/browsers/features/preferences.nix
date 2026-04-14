{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.preferences;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.preferences = {

            restoreLastSession = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Restore tabs from the previous session on startup.";
            };

            showBookmarksBar = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Show the bookmarks bar by default.";
            };

            systemTheme = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "system"
                  "dark"
                  "light"
                ]
              );
              default = null;
              description = "Enforce browser UI theme.";
            };

            cleanUi = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables annoying visual clutter, such as the Google Search Side Panel
                and promotional "What's New" UI popups.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            # Map to Enterprise Policies
            internal.policies = lib.mkMerge [
              (lib.mkIf (cfg.restoreLastSession != null) {
                "RestoreOnStartup" = if cfg.restoreLastSession then 1 else 5; # 1=Restore, 5=New Tab
              })
              (lib.mkIf cfg.cleanUi {
                "GoogleSearchSidePanelEnabled" = false;
                "PromotionsEnabled" = false;
              })
              { "DefaultBrowserSettingEnabled" = false; } # Always prevent "make default" nagging
            ];

            # Map to Initial Preferences (First Run)
            internal.initialPreferences = lib.mkMerge [
              {
                "browser" = {
                  "show_home_button" = false;
                  "custom_chrome_frame" = false;
                }
                // lib.optionalAttrs (cfg.showBookmarksBar != null) {
                  "show_bookmarks_bar" = cfg.showBookmarksBar;
                };

                "bookmarks" =
                  if (cfg.showBookmarksBar != null) then
                    {
                      "show_on_all_tabs" = cfg.showBookmarksBar;
                    }
                  else
                    { };

                "extensions" =
                  if (cfg.systemTheme != null) then
                    {
                      "theme" = {
                        "id" = "";
                        "system_theme" =
                          if cfg.systemTheme == "system" then 1 else (if cfg.systemTheme == "dark" then 2 else 3);
                      };
                    }
                  else
                    { };

                "distribution" = {
                  "do_not_create_desktop_shortcut" = true;
                  "do_not_create_quick_launch_shortcut" = true;
                  "import_bookmarks" = false;
                  "import_history" = false;
                };
              }
            ];
          };
        }
      )
    );
  };
}
