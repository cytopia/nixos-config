{ lib, config, ... }:

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

            forceHardwareMesa = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Strictly forces Mesa-based drivers (Intel, AMD, Nouveau) to use the physical GPU.
                Injects `LIBGL_ALWAYS_SOFTWARE=0` to prevent silent, battery-draining fallbacks
                to CPU software rendering (llvmpipe) if the driver pipeline hits a minor error.

                Note: This has no effect on proprietary Nvidia drivers, as they do not
                respect Mesa environment variables.
              '';
            };

            hideVulkanLoader = lib.mkOption {
              type = lib.types.bool;
              default = false; # MUST be false by default!
              description = ''
                Completely blinds the browser to physical Vulkan drivers by passing an empty
                `VK_ICD_FILENAMES` environment variable.

                Use this ONLY as a last-resort workaround if the GPU sandbox fatally crashes
                on startup while probing experimental or broken Vulkan drivers
                (e.g., Intel 'xe' kernel drivers on Tiger Lake hardware under Wayland).

                WARNING: Enabling this will successfully stop the crash, but it will force
                the Dawn engine (WebGPU) to fall back to SwiftShader (CPU emulation),
                disabling hardware-accelerated WebGPU.
              '';
            };

            disabledVulkanLayers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "VK_LAYER_OBS_vkcapture_32" "VK_LAYER_OBS_vkcapture_64" "VK_LAYER_MANGOHUD_overlay" ];
              description = ''
                A list of Vulkan layers to explicitly block from loading into the browser.

                Browsers heavily sandbox their GPU processes. External Vulkan implicit layers
                (like OBS Game Capture, MangoHud, or ReShade) often try to inject themselves
                into the browser's render loop, leading to immediate GPU process crashes.

                Note: You can also pass `[ "~all~" ]` to aggressively block EVERY implicit layer.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.forceHardwareMesa {
                "LIBGL_ALWAYS_SOFTWARE" = "0";
              })
              (lib.mkIf cfg.hideVulkanLoader {
                "VK_ICD_FILENAMES" = "";
              })
              (lib.mkIf (cfg.disabledVulkanLayers != []) {
                # This perfectly translates your Nix list ["a", "b"] into the
                # exact comma-separated string "a,b" that the Vulkan loader expects!
                "VK_LOADER_LAYERS_DISABLE" = lib.concatStringsSep "," cfg.disabledVulkanLayers;
              })
            ];

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

  ###
  ### 3. GLOBAL SYSTEM CONFIGURATION
  ###
  config = {
    # We map the assertion to the top-level NixOS system config.
    # This loops through every browser you define and checks for the paradox.
    assertions = lib.mapAttrsToList (
      name: browserCfg:
      let
        cfg = browserCfg.features.hardware.graphics;
      in
      {
        assertion = !(cfg.hideVulkanLoader && cfg.backend == "vulkan");
        message = ''
          cytopia.programs.browsers.${name}: You cannot set `hideVulkanLoader = true`
          while `backend = "vulkan"`. This creates a paradox where the browser
          is forced to use Vulkan but is blinded to the physical drivers,
          guaranteeing a fatal GPU crash.
        '';
      }
    ) config.cytopia.programs.browsers;
  };
}
