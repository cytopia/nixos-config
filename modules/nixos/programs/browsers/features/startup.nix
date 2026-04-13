{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.startup;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.startup = {

            extraEnvVars = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = ''
                Environment variables to export before launching the browser.
                These are injected directly into the executable wrapper.
                Example: { "VK_LOADER_LAYERS_DISABLE" = "VK_LAYER_OBS_vkcapture_32,VK_LAYER_OBS_vkcapture_64"; }
              '';
            };

            extraFlags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Add additional raw command-line flags to the browser startup.";
            };

            extraEnableFeatures = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Add additional features to the --enable-features list.";
            };

            extraDisableFeatures = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Add additional features to the --disable-features list.";
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            # We simply pass these raw values directly into our internal architecture
            # so the main wrapper script can consume them.
            internal.envVars = cfg.extraEnvVars;
            internal.flags = cfg.extraFlags;
            internal.enableFeatures = cfg.extraEnableFeatures;
            internal.disableFeatures = cfg.extraDisableFeatures;
          };
        }
      )
    );
  };
}
