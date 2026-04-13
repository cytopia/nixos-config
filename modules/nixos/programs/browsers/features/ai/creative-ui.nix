{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.ai.creativeUi;
        in
        {
          options.features.ai.creativeUi = {
            disableGenAiThemes = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                [REMOTE/CLOUD] Disables the "Create with AI" button in the browser's appearance settings.
                This stops the browser from using AI to generate custom window colors
                and background images based on a text prompt you type.
              '';
            };
          };

          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableGenAiThemes {
                # 2 = Blocked. Kills the AI-powered custom browser theme and wallpaper generator.
                "CreateThemesSettings" = 2;
              })
            ];
          };
        }
      )
    );
  };
}
