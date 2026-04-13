{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.rasterization;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.rasterization = {

            enableGpuRasterization = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Offload basic HTML/CSS painting operations from the CPU to the GPU.
              '';
            };

            enableOopCanvas = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Out-of-Process (OOP) Canvas Rasterization.
                Offloads heavy 2D canvas drawing (like Google Maps) to a separate, dedicated
                GPU process thread to prevent UI freezing and increase performance.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.enableGpuRasterization [
                "--enable-gpu-rasterization"
              ])
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.enableOopCanvas [
                "CanvasOopRasterization"
              ])
            ];
          };
        }
      )
    );
  };
}
