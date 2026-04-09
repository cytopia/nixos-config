{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.extensions;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.extensions = {
            forceInstall = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of Chrome extension IDs to silently force-install.";
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = lib.mkIf (cfg.forceInstall != [ ]) {
            internal.policies = {
              "ExtensionSettings" = lib.genAttrs cfg.forceInstall (extId: {
                "installation_mode" = "force_installed";
                "update_url" = "https://clients2.google.com/service/update2/crx";
                "toolbar_pin" = "default_unpinned";
              });
            };
          };
        }
      )
    );
  };
}
