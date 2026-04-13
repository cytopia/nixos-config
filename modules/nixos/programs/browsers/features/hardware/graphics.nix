{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.graphics;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.graphics = {

            backend = lib.mkOption {
              type = lib.types.enum [
                "vulkan"
                "gl"
                "gles"
              ];
              default = "gl";
              description = ''
                The underlying graphics rendering API to translate to via ANGLE.
                Vulkan uses modern, low-overhead APIs to draw the browser UI, significantly
                reducing CPU draw calls compared to legacy OpenGL.
              '';
            };

            skiaGraphite = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Replaces Ganesh with the next-gen Skia Graphite 2D renderer.
                Currently hard-blocked by Chromium on X11; keep FALSE until fully supported
                by your specific graphics driver and display server combination.
              '';
            };

            treesInViz = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Moves the Display Tree to the Viz compositor thread to reduce input latency.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.mkIf (cfg.backend == "vulkan") [
                "--use-gl=angle"
                "--use-angle=vulkan"
                "--use-vulkan"
                "--vulkan-implementation=native"
              ])
              (lib.mkIf (cfg.backend == "gl") [
                "--use-gl=angle"
                "--use-angle=gl"
                "--disable-vulkan"
              ])
              (lib.mkIf (cfg.backend == "gles") [
                "--use-gl=angle"
                "--use-angle=gles"
                "--disable-vulkan"
              ])
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.mkIf (cfg.backend == "vulkan") [
                "Vulkan"
                "VulkanFromANGLE"
                "DefaultANGLEVulkan"
              ])
              (lib.optionals cfg.skiaGraphite [ "SkiaGraphite" ])
              (lib.optionals cfg.treesInViz [ "TreesInViz" ])
            ];

            internal.disableFeatures = lib.mkMerge [
              (lib.mkIf (cfg.backend == "gl" || cfg.backend == "gles") [
                "Vulkan"
                "VulkanFromANGLE"
                "DefaultANGLEVulkan"
              ])
            ];
          };
        }
      )
    );
  };
}
