{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai;
        in
        {

          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.ai = {

            disableGemini = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Strictly blocks the Gemini assistant app integration in the side panel
                and browser UI. Prevents Gemini from "acting on web pages" (reading your
                active DOM) and suppresses the Gemini intro splash screen.
              '';
            };

            disableGenAiFeatures = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables cloud-powered productivity features:
                - Master GenAI Kill-switch (GenAiDefaultSettings)
                - AI History Search (natural language queries) and History Grouping (Journeys).
                - Tab Compare (AI product comparisons) and "Help me write" (AI text generator).
                - ML-driven "Smart" Contextual Search and Web Annotations.
                - Suppresses the general AI feature intro screens.
              '';
            };

            disableGenAiThemes = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables the "Create with AI" button in the browser's appearance settings.
                This stops the browser from using AI to generate custom window colors
                and background images based on a text prompt you type.
              '';
            };

            disableDevAi = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables AI help inside the Developer Tools (F12). This stops Chrome
                from offering AI-generated explanations for coding errors, network
                issues, or website performance logs when you are inspecting a site.
              '';
            };

            disableLocalAiModels = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [LOCAL/ON-DEVICE] Hard-blocks the background download of foundational AI models to the local disk.
                Disables the Javascript APIs that allow websites to use the on-device
                AI engine (LanguageModel, Summarization, Rewriter).
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.policies = lib.mkMerge [

              # Gemini Assistant Pillar (REMOTE)
              (lib.mkIf cfg.disableGemini {
                # 1 = Blocked. Kills the Gemini app and its entry points in the side panel/UI.
                "GeminiSettings" = 1;
                # 1 = Blocked. Prevents Gemini from reading the content/DOM of your active tabs.
                "GeminiActOnWebSettings" = 1;
                # Suppresses the full-screen "Try Gemini" welcome screen on startup.
                "ShowGeminiIntroScreenEnabled" = false;
              })

              # Generative AI Productivity Pillar (REMOTE)
              (lib.mkIf cfg.disableGenAiFeatures {
                # The 2026 Master Toggle. 1 = Disabled. Acts as a root kill-switch for GenAI.
                "GenAiDefaultSettings" = 1;

                # 2 = Blocked. Kills natural language AI search for your browsing history.
                "HistorySearchSettings" = 2;
                # Kills the ML-driven grouping of history into "Journeys/Clusters."
                "HistoryClustersVisible" = false;
                # 2 = Blocked. Kills the feature that uses AI to compare products across multiple tabs.
                "TabCompareSettings" = 2;
                # 2 = Blocked. Kills the AI assistant that helps draft or rewrite text in form fields.
                "HelpMeWriteSettings" = 2;
                # Kills the "Web Annotations" feature where Google's ML highlights page content for you.
                "WebAnnotations" = false;
                # Kills the ML-powered "Touch to Search" and context-aware intent scanning.
                "ContextualSearchEnabled" = false;

                # 1 = Blocked. Kills the general "AI Mode" integration and its UI toggles.
                "AIModeSettings" = 1;
                # 1 = Blocked. Stops Chrome from sharing multi-tab context/data with cloud AI engines.
                "SearchContentSharingSettings" = 1;
                # Suppresses the "Welcome to new AI features" splash screen on startup.
                "ShowAiIntroScreenEnabled" = false;
              })

              # Creative/UI Pillar (REMOTE)
              (lib.mkIf cfg.disableGenAiThemes {
                # 2 = Blocked. Kills the AI-powered custom browser theme and wallpaper generator.
                "CreateThemesSettings" = 2;
              })

              # Developer Pillar (REMOTE)
              (lib.mkIf cfg.disableDevAi {
                # 2 = Blocked. Kills AI-generated insights and error explanations inside the DevTools console.
                "DevToolsGenAiSettings" = 2;
              })

              # Local Engine Pillar (LOCAL)
              (lib.mkIf cfg.disableLocalAiModels {
                # 1 = Blocked. Stops the browser from silently downloading large LLM models to the local disk.
                "GenAILocalFoundationalModelSettings" = 1;
                # Disables 'window.ai' and related APIs, preventing JS from using your local hardware for AI.
                "BuiltInAIAPIsEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
