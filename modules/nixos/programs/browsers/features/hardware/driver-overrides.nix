{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.driverOverrides;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.driverOverrides = {

            ignoreGpuBlocklist = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Force hardware acceleration on experimental/uncertified drivers.
                Bypasses the hardcoded driver-version check in Chromium's internal blacklist.
              '';
            };

            disableBugWorkarounds = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                DANGEROUS: If true, disables Chromium's internal driver bug workarounds.
                Keep this FALSE on Intel Xe to maintain high WebGL draw-call performance.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.ignoreGpuBlocklist [
                "--ignore-gpu-blocklist"
              ])
              (lib.optionals cfg.disableBugWorkarounds [
                "--disable-gpu-driver-bug-workarounds"
              ])
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.ignoreGpuBlocklist [
                "VaapiIgnoreDriverChecks"
              ])
            ];
          };
        }
      )
    );
  };
}
