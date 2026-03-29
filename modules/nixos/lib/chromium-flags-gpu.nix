let

  displayServerStrategy = {
    all = {
      flags = [ ];
      enableFeatures = [
        # Force Wayland native screen sharing
        "WebRTCPipeWireCapturer"
      ];
      disableFeatures = [ ];
    };
    wayland = {
      flags = [
        "--ozone-platform=wayland"
        "--ozone-platform-hint=wayland"
      ];
      enableFeatures = [
        "WaylandWindowDecorations"
      ];
      disableFeatures = [ ];
    };
    xWaylandAndX11 = {
      flags = [
        "--ozone-platform=x11"
      ];
      enableFeatures = [ ];
      disableFeatures = [ ];
    };
  };

  renderingEngine = {
    all = { };
    vulkan = {
      flags = [
        "--use-gl=angle"
        "--use-angle=vulkan"
        "--use-vulkan"
        "--vulkan-implementation=native"
      ];
      enableFeatures = [
        "Vulkan"
        "VulkanFromANGLE"
        "DefaultANGLEVulkan"
      ];
      disableFeatures = [ ];
    };
    gl = {
      flags = [
        "--use-gl=angle"
        "--use-angle=gl"
        "--disable-vulkan"
      ];
      enableFeatures = [ ];
      disableFeatures = [
        "Vulkan"
        "VulkanFromANGLE"
        "DefaultANGLEVulkan"
      ];
    };
    gles = {
      flags = [
        "--use-gl=angle"
        "--use-angle=gles"
        "--disable-vulkan"
      ];
      enableFeatures = [ ];
      disableFeatures = [
        "Vulkan"
        "VulkanFromANGLE"
        "DefaultANGLEVulkan"
      ];
    };
  };

  videoAcceleration = {
    all = {
      flags = [ ];
      enableFeatures = [
        "VaapiVideoDecoder"
        "VaapiVideoEncoder"
        "AcceleratedVideoEncoder"
        "AcceleratedVideoDecoder"
        "PlatformVideoEncoder"
      ];
      disableFeatures = [
        "UseChromeOSDirectVideoDecoder"
      ];
    };
    vulkan = {
      flags = [ ];
      enableFeatures = [
        "VulkanVideoDecoder"
        "VulkanVideoEncoder"
      ];
      disableFeatures = [
        "VaapiVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxZeroCopyGL"
      ];
    };
    gl = {
      flags = [ ];
      enableFeatures = [
        "VaapiVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxZeroCopyGL"
      ];
      disableFeatures = [
        "VulkanVideoDecoder"
        "VulkanVideoEncoder"
      ];
    };
    gles = {
      flags = [ ];
      enableFeatures = [
        "VaapiVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxZeroCopyGL"
      ];
      disableFeatures = [
        "VulkanVideoDecoder"
        "VulkanVideoEncoder"
      ];
    };
  };

  gpuRasterization = {
    all = {
      flags = [
        "--enable-gpu-rasterization"
      ];
      enableFeatures = [
        "CanvasOopRasterization"
      ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };
  memoryManagement = {
    all = {
      flags = [
        "--enable-zero-copy"
        "--enable-native-gpu-memory-buffers"
      ];
      enableFeatures = [ ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  ignoreGpuBlocklist = {
    all = {
      flags = [
        # Ignore if my GPU is blocked by Chromium and initialize
        "--ignore-gpu-blocklist"
      ];
      disableFeatures = [ ];
      enableFeatures = [
        # Bypass hardcoded driver-version check in black list
        "VaapiIgnoreDriverChecks"
      ];
    };
    vulkan = { };
    gl = { };
    gles = { };

  };
  safetyOverrides = {
    all = {
      flags = [
        "--disable-gpu-driver-bug-workarounds"
      ];
      disableFeatures = [ ];
      enableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  skiaGraphite = {
    all = {
      flags = [ ];
      enableFeatures = [
        "SkiaGraphite"
      ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  treesInViz = {
    all = {
      flags = [ ];
      enableFeatures = [
        "TreesInViz"
      ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  webNN = {
    all = {
      flags = [ ];
      enableFeatures = [
        "WebMachineLearningNeuralNetwork"
      ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

in
{
  # The main exposed function
  getChromeHardwareFlags =
    {
      display_server ? "wayland", # Accepts "wayland" or "xwayland"
      engine ? "vulkan", # Accepts "vulkan", "gl", or "gles"
      enableVideoAcceleration ? true,
      enableGpuRasterization ? true,
      enableMemoryManagement ? true,
      enableIgnoreGpuBlocklist ? true,
      enableSafetyOverrides ? false,
      enableFeatureTreesInViz ? true,
      enableFeatureSkiaGraphite ? false,
      enableFeatureWebNn ? true,
    }:
    let
      # Map user-friendly input to the internal data structure key
      displayTarget = if display_server == "xwayland" then "xWaylandAndX11" else display_server;

      # Helper function to cleanly extract arrays, falling back to empty lists to avoid null errors
      extract =
        block: target: prop:
        (block.all.${prop} or [ ]) ++ (block.${target}.${prop} or [ ]);

      # Helper function that only extracts if the boolean toggle is true
      extractIf =
        condition: block: target: prop:
        if condition then extract block target prop else [ ];
    in
    {
      flags =
        extract displayServerStrategy displayTarget "flags"
        ++ extract renderingEngine engine "flags"
        ++ extractIf enableVideoAcceleration videoAcceleration engine "flags"
        ++ extractIf enableGpuRasterization gpuRasterization engine "flags"
        ++ extractIf enableMemoryManagement memoryManagement engine "flags"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "flags"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "flags"
        ++ extractIf enableFeatureSkiaGraphite skiaGraphite engine "flags"
        ++ extractIf enableFeatureTreesInViz treesInViz engine "flags"
        ++ extractIf enableFeatureWebNn webNN engine "flags";
      enableFeatures =
        extract displayServerStrategy displayTarget "enableFeatures"
        ++ extract renderingEngine engine "enableFeatures"
        ++ extractIf enableVideoAcceleration videoAcceleration engine "enableFeatures"
        ++ extractIf enableGpuRasterization gpuRasterization engine "enableFeatures"
        ++ extractIf enableMemoryManagement memoryManagement engine "enableFeatures"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "enableFeatures"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "enableFeatures"
        ++ extractIf enableFeatureSkiaGraphite skiaGraphite engine "enableFeatures"
        ++ extractIf enableFeatureTreesInViz treesInViz engine "enableFeatures"
        ++ extractIf enableFeatureWebNn webNN engine "enableFeatures";
      disableFeatures =
        extract displayServerStrategy displayTarget "disableFeatures"
        ++ extract renderingEngine engine "disableFeatures"
        ++ extractIf enableVideoAcceleration videoAcceleration engine "disableFeatures"
        ++ extractIf enableGpuRasterization gpuRasterization engine "disableFeatures"
        ++ extractIf enableMemoryManagement memoryManagement engine "disableFeatures"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "disableFeatures"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "disableFeatures"
        # If the feature is ON, extract any explicitly defined disableFeatures
        ++ extractIf enableFeatureSkiaGraphite skiaGraphite engine "disableFeatures"
        ++ extractIf enableFeatureTreesInViz treesInViz engine "disableFeatures"
        ++ extractIf enableFeatureWebNn webNN engine "disableFeatures"
        # If the feature is OFF, mathematically force it into the disabled array
        ++ extractIf (!enableFeatureSkiaGraphite) skiaGraphite engine "enableFeatures"
        ++ extractIf (!enableFeatureTreesInViz) treesInViz engine "enableFeatures"
        ++ extractIf (!enableFeatureWebNn) webNN engine "enableFeatures";
    };
}
