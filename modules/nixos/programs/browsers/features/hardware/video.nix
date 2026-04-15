{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.video;
          # Read the graphics backend from our sister module to determine bridge compatibility
          renderBackend = config.features.hardware.graphics.backend;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.video = {

            decodingBackend = lib.mkOption {
              type = lib.types.enum [
                "vaapi"
                "vulkan"
                "none"
              ];
              default = "vaapi";
              description = ''
                Selects the hardware-accelerated video decoding/encoding engine.
                - "vaapi": The mature, stable Linux standard (Highly recommended for Intel Xe).
                - "vulkan": The experimental next-gen standard. Requires bleeding-edge drivers.
                - "none": Forces CPU software decoding (Terrible for battery life).
                Note: These are mutually exclusive. Nix ensures they do not collide.
              '';
            };

           blockSoftwareEncoders = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                KILLS software AV1 encoding so WebRTC apps (like Google Meet) are forced
                to fall back to hardware-accelerated VP9 or H264.
                Check via: 'vainfo | grep AV1'.
                If you see 'VAEntrypointEncSlice' it is supported, then set this option to false.
                If you see 'VAEntrypointVLD', it is not supported, then set this option to true.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.enableFeatures = lib.mkMerge [
              # --- MASTER HARDWARE GREEN LIGHTS ---
              (lib.mkIf (cfg.decodingBackend != "none") [
                # These act as the master "Green Lights" telling the browser:
                # "Yes, you are allowed to use the physical GPU chip for video tasks."
                "AcceleratedVideoEncoder"
                "AcceleratedVideoDecoder"
                "PlatformVideoEncoder"
              ])

              # --- VA-API BACKEND LOGIC ---
              (lib.mkIf (cfg.decodingBackend == "vaapi") [
                "VaapiVideoDecoder"
                "VaapiVideoEncoder"
              ])
              # The VA-API to OpenGL bridge is only needed if rendering via GL/GLES
              (lib.mkIf (cfg.decodingBackend == "vaapi" && (renderBackend == "gl" || renderBackend == "gles")) [
                # If the browser draws the screen using OpenGL, but processes video using VA-API,
                # they speak different languages. This feature builds a "bridge" to pass the
                # decoded video pictures smoothly to the screen.
                "VaapiVideoDecodeLinuxGL"
              ])

              # --- VULKAN BACKEND LOGIC ---
              (lib.mkIf (cfg.decodingBackend == "vulkan") [
                "VulkanVideoDecoder"
                "VulkanVideoEncoder"
              ])
            ];

            internal.disableFeatures = lib.mkMerge [
              [
                # This is a specific engine meant only for Chromebooks. We are on standard Linux,
                # so we turn it off to prevent the browser from getting confused.
                "UseChromeOSDirectVideoDecoder"
                # These are old, legacy ways of playing video from many years ago.
                # We turn them off to force the browser to use the modern engines we enabled above.
                "AcceleratedVideoDecodeLinuxGL"
                "AcceleratedVideoDecodeLinuxZeroCopyGL"
              ]
              (lib.optionals cfg.blockSoftwareEncoders [
                # AV1 is a high-quality video format, but if your physical hardware chip doesn't
                # support it, the CPU will try to do it via "Software". This causes massive battery drain
                # and heat. Turning this off forces the browser to say "I don't support AV1" to Google Meet,
                # forcing the call to use a battery-friendly format like VP9 instead.
                "AomVideoEncoder"
              ])

              # --- MUTUAL EXCLUSION BLOCKS ---

              # If using VA-API, strictly kill Vulkan media extensions
              (lib.mkIf (cfg.decodingBackend == "vaapi") [
                "VulkanVideoDecoder"
                "VulkanVideoEncoder"
              ])
              # Also, if rendering with Vulkan but decoding with VA-API, kill the GL bridge to stop crash loops
              (lib.mkIf (cfg.decodingBackend == "vaapi" && renderBackend == "vulkan") [
                # If we draw the screen with Vulkan, but decode with VA-API, having an OpenGL bridge
                # sitting in the middle causes the browser to instantly crash. We burn the bridge here.
                "VaapiVideoDecodeLinuxGL"
              ])

              # If using Vulkan Video, strictly kill VA-API media extensions
              (lib.mkIf (cfg.decodingBackend == "vulkan") [
                # We are using Vulkan, so we must explicitly block the VA-API video engines
                # and their bridges from turning on and causing a traffic jam.
                "VaapiVideoDecoder"
                "VaapiVideoEncoder"
                "VaapiVideoDecodeLinuxGL"
              ])

              # If "none", kill everything
              (lib.mkIf (cfg.decodingBackend == "none") [
                "VaapiVideoDecoder"
                "VaapiVideoEncoder"
                "VulkanVideoDecoder"
                "VulkanVideoEncoder"
                "AcceleratedVideoEncoder"
                "AcceleratedVideoDecoder"
              ])
            ];
          };
        }
      )
    );
  };
}
