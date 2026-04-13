{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai.developer;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.ai.developer = {
            disableDevAi = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables AI help inside the Developer Tools (F12). This stops Chrome
                from offering AI-generated explanations for coding errors, network
                issues, or website performance logs when you are inspecting a site.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableDevAi {
                # 2 = Blocked. Kills AI-generated insights and error explanations inside the DevTools console.
                "DevToolsGenAiSettings" = 2;
              })
            ];
          };
        }
      )
    );
  };
}
