let

  # TODO: Make one profile for Chromium (mainly Youtube)
  #       Make one profile for Google Chrome (mainly Google Meet)

  ###
  ### Display Server (Wayland vs XWayland/X11)
  ###
  displayServerStrategy = {
    all = {
      flags = [ ];
      enableFeatures = [
        # Force Wayland native screen sharing
        # Ensures Wayland uses the modern, efficient PipeWire backend instead of legacy X11 grabbing.
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
        # Tells Wayland (Sway) to handle the window borders cleanly.
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

  ###
  ### Rendering (Vulkan vs GL vs GLES)
  ###
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
        # Uses the modern, low-overhead Vulkan API to draw the browser UI, reducing CPU draw calls.
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

  ###
  ### Video Acceleration
  ###
  videoAcceleration = {
    all = {
      flags = [
        # CRITICAL for Intel xe: Allows compositor to read raw NV12 hardware formats natively.
        # IMPORTANT: This gives issues with Google Meet background blur, but on the other hand
        # improves playback speed of Youtube videos (and safes battery life)
        "--use-multi-plane-format-for-hardware-video"
      ];
      enableFeatures = [
        # The core hardware decode/encode engines
        "VaapiVideoDecoder"
        "VaapiVideoEncoder"
        "AcceleratedVideoEncoder"
        "AcceleratedVideoDecoder"
        "PlatformVideoEncoder"
      ];
      disableFeatures = [
        "UseChromeOSDirectVideoDecoder"
        # KILLS software AV1 encoding so Google Meet is forced to use hardware VP9/H264
        "AomVideoEncoder"
        # Legacy decoding architectures. We want the modern VaapiVideoDecoder instead.
        "AcceleratedVideoDecodeLinuxGL"
        "AcceleratedVideoDecodeLinuxZeroCopyGL"
      ];
    };
    vulkan = {
      flags = [ ];
      enableFeatures = [
        # We have disabled them
        #"VulkanVideoDecoder"
        #"VulkanVideoEncoder"
      ];
      disableFeatures = [
        # PREVENTS the "Importing textures... into GL" crash loop in your logs
        "VaapiVideoDecodeLinuxGL"
      ];
    };
    gl = {
      flags = [ ];
      enableFeatures = [
        # The bridge connecting VA-API to OpenGL. Required for GL/GLES.
        "VaapiVideoDecodeLinuxGL"
      ];
      disableFeatures = [
        "VulkanVideoDecoder"
        "VulkanVideoEncoder"
      ];
    };
    gles = {
      flags = [ ];
      enableFeatures = [
        # The bridge connecting VA-API to OpenGL. Required for GL/GLES.
        "VaapiVideoDecodeLinuxGL"
      ];
      disableFeatures = [
        "VulkanVideoDecoder"
        "VulkanVideoEncoder"
      ];
    };
  };

  ###
  ### GPU Rasterization
  ###
  gpuRasterization = {
    all = {
      flags = [
        "--enable-gpu-rasterization"
      ];
      enableFeatures = [
        # Offloads 2D canvas drawing (like Google Maps) to a separate GPU process thread for better performance
        "CanvasOopRasterization"
      ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  ###
  ### Memory Management
  ###
  memoryManagement = {
    all = {
      flags = [
        # Allows the GPU to read pixel data directly from memory without the CPU copying it first.
        "--enable-zero-copy"
        # Pairs with zero-copy to allow the Wayland compositor and the browser to share DMA-BUFs directly.
        "--enable-native-gpu-memory-buffers"
      ];
      enableFeatures = [ ];
      disableFeatures = [ ];
    };
    vulkan = { };
    gl = { };
    gles = { };
  };

  ###
  ### Driver ignores
  ###
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
  getFlags =
    {
      display_server ? "wayland", # Accepts "wayland" or "xwayland"
      engine ? "vulkan", # Accepts "vulkan", "gl", or "gles"
      enableGpuRasterization ? true,
      enableMemoryManagement ? true,
      enableFeatureVideoAcceleration ? true,
      enableFeatureTreesInViz ? true,
      enableFeatureSkiaGraphite ? false,
      enableFeatureWebNn ? true,
      enableIgnoreGpuBlocklist ? true,
      enableSafetyOverrides ? false,
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
        ++ extractIf enableGpuRasterization gpuRasterization engine "flags"
        ++ extractIf enableMemoryManagement memoryManagement engine "flags"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "flags"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "flags"
        ++ extractIf enableFeatureVideoAcceleration videoAcceleration engine "flags"
        ++ extractIf enableFeatureSkiaGraphite skiaGraphite engine "flags"
        ++ extractIf enableFeatureTreesInViz treesInViz engine "flags"
        ++ extractIf enableFeatureWebNn webNN engine "flags";
      enableFeatures =
        extract displayServerStrategy displayTarget "enableFeatures"
        ++ extract renderingEngine engine "enableFeatures"
        ++ extractIf enableGpuRasterization gpuRasterization engine "enableFeatures"
        ++ extractIf enableMemoryManagement memoryManagement engine "enableFeatures"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "enableFeatures"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "enableFeatures"
        ++ extractIf enableFeatureVideoAcceleration videoAcceleration engine "enableFeatures"
        ++ extractIf enableFeatureSkiaGraphite skiaGraphite engine "enableFeatures"
        ++ extractIf enableFeatureTreesInViz treesInViz engine "enableFeatures"
        ++ extractIf enableFeatureWebNn webNN engine "enableFeatures";
      disableFeatures =
        extract displayServerStrategy displayTarget "disableFeatures"
        ++ extract renderingEngine engine "disableFeatures"
        ++ extractIf enableGpuRasterization gpuRasterization engine "disableFeatures"
        ++ extractIf enableMemoryManagement memoryManagement engine "disableFeatures"
        ++ extractIf enableIgnoreGpuBlocklist ignoreGpuBlocklist engine "disableFeatures"
        ++ extractIf enableSafetyOverrides safetyOverrides engine "disableFeatures"
        ++ extractIf enableFeatureVideoAcceleration videoAcceleration engine "disableFeatures"
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
