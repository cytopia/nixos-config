{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai.gemini;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.ai.gemini = {
            disableGemini = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Strictly blocks the Gemini assistant app integration in the side panel
                and browser UI. Prevents Gemini from "acting on web pages" (reading your
                active DOM) and suppresses the Gemini intro splash screen.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableGemini {
                # 1 = Blocked. Kills the Gemini app and its entry points in the side panel/UI.
                "GeminiSettings" = 1;
                # 1 = Blocked. Prevents Gemini from reading the content/DOM of your active tabs.
                "GeminiActOnWebSettings" = 1;
              })
            ];
          };
        }
      )
    );
  };
}
