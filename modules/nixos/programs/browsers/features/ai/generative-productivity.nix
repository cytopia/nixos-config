{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai.generativeProductivity;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.ai.generativeProductivity = {

            disableMasterGenAiSwitch = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] The root GenAI kill-switch (GenAiDefaultSettings).
                If disabled, this overrides ALL other generative AI features and disables them.
              '';
            };

            disableContextSharing = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Stops Chrome from sharing multi-tab context and page data
                with cloud AI engines (SearchContentSharingSettings).
              '';
            };

            disableAiMode = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Kills the general "AI Mode" integration and its UI toggles.
                Also suppresses the "Welcome to new AI features" splash screen on startup.
              '';
            };

            disableAiHistorySearch = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables natural language AI search for your browsing history.
              '';
            };

            disableTabCompare = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Kills the feature that uses AI to compare products across multiple tabs.
              '';
            };

            disableHelpMeWrite = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Kills the AI assistant that helps draft or rewrite text in form fields.
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableMasterGenAiSwitch {
                "GenAiDefaultSettings" = 1;
              })

              (lib.mkIf cfg.disableContextSharing {
                "SearchContentSharingSettings" = 1;
              })

              (lib.mkIf cfg.disableAiMode {
                "AIModeSettings" = 1;
              })

              (lib.mkIf cfg.disableAiHistorySearch {
                "HistorySearchSettings" = 2;
              })

              (lib.mkIf cfg.disableTabCompare {
                "TabCompareSettings" = 2;
              })

              (lib.mkIf cfg.disableHelpMeWrite {
                "HelpMeWriteSettings" = 2;
              })
            ];
          };
        }
      )
    );
  };
}
