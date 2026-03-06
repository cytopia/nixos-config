{ config, pkgs, ... }:


{
  ###
  ### Kernel Settings
  ###

  # Allow the kernel to load the necessary Intel binary blobs
  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [
    "i915.enable_guc=3"  # Advanced Powermanagement and Video features (GuC/HuC)
    "i915.enable_fbc=1"  # Frame buffer compression
  ];


  ###
  ### GPU Driver and Frameworks
  ###
  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      # 1. Video Acceleration (VA-API)
      intel-media-driver      # The modern iHD driver for Tiger Lake+
      # 2. QuickSync Video (QSV)
      vpl-gpu-rt              # The modern oneVPL runtime for Tiger Lake+
      # 3. Compute (OpenCL / Level Zero)
      intel-compute-runtime   # The "NEO" runtime
      intel-graphics-compiler # Essential for compute shaders
      # 4. Vulkan & Support
      vulkan-loader
      vulkan-validation-layers
    ];
  };


  ###
  ### Environment Variables
  ###
  environment.sessionVariables = {
    # Tell the system to prefer the modern Intel driver for video
	LIBVA_DRIVER_NAME = "iHD";
  };


  ###
  ### Additional GPU Monitoring & Info Tools
  ###
  environment.systemPackages = with pkgs; [
    nvtopPackages.intel    # Beautiful TTY GPU monitor (shows usage/power/freq)
    vulkan-tools           # Provides 'vulkaninfo'
    libva-utils            # Provides 'vainfo' (verifies video acceleration)
    mesa-demos             # Provides 'glxinfo' (verifies OpenGL)
    clinfo                 # Verifies OpenCL (intel-compute-runtime)
  ];
}
