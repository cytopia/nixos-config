{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.memory;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.memory = {

            enableZeroCopy = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Allows the GPU to read pixel data directly from memory without the
                CPU copying it first.
              '';
            };

            enableNativeGpuBuffers = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Pairs with zero-copy to allow the Wayland compositor and the browser
                to share DMA-BUFs directly without translation.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.enableZeroCopy [
                "--enable-zero-copy"
              ])
              (lib.optionals cfg.enableNativeGpuBuffers [
                "--enable-native-gpu-memory-buffers"
              ])
            ];
          };
        }
      )
    );
  };
}
