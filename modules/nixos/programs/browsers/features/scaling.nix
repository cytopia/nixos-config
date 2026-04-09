{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.scaling;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.scaling = {
            factor = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "UI scaling factor (1.0 is native, 1.5 is 150%).";
            };
            waylandFractionalScaling = lib.mkOption {
              type = lib.types.bool;
              default = false; # Default false so it's a true no-op until requested
              description = "Enables WaylandFractionalScaleV1 for crisp Sway rendering.";
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            # Only inject if the user is changing it from the 1.0 default
            internal.flags = lib.optional (
              cfg.factor != 1.0
            ) "--force-device-scale-factor=${builtins.toJSON cfg.factor}";

            # Only inject the specific fractional scaling feature
            internal.enableFeatures = lib.optional cfg.waylandFractionalScaling "WaylandFractionalScaleV1";
          };
        }
      )
    );
  };
}
