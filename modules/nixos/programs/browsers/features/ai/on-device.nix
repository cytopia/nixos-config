{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai.onDevice;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.ai.onDevice = {

            disableLocalAiModels = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [LOCAL/ON-DEVICE] Hard-blocks the background download of foundational AI models to the local disk.
                Disables the Javascript APIs that allow websites to use the on-device
                AI engine (LanguageModel, Summarization, Rewriter).
              '';
            };

            disableHistoryClusters = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [LOCAL/ML] Kills the traditional ML-driven grouping of your history into "Journeys/Clusters."
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableLocalAiModels {
                # 1 = Blocked. Stops the browser from silently downloading large LLM models to the local disk.
                "GenAILocalFoundationalModelSettings" = 1;
                # Disables 'window.ai' and related APIs, preventing JS from using your local hardware for AI.
                "BuiltInAIAPIsEnabled" = false;
              })

              (lib.mkIf cfg.disableHistoryClusters {
                "HistoryClustersVisible" = false;
              })
            ];
          };
        }
      )
    );
  };
}
