{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.hardware.intel-gpu;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.hardware.intel-gpu = {
    enable = lib.mkEnableOption "Optimized Intel GPU support (Gen 12+ / Tiger Lake and newer)";

    useXeDriver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the modern 'xe' kernel driver instead of legacy 'i915'. Recommended for Gen 12+.
        WARNING: This requires Linux kernel 6.8 or newer (uname -r).
      '';
    };

    # Must be set, if useXeDriver is true
    deviceId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "46a6";
      description = ''
        The PCI device ID for the Intel GPU. This is mandatory if useXeDriver is enabled.
        Use 'lspci -nn | grep VGA' and look at the 4 digits:
        'TigerLake-H GT1 [UHD Graphics] [8086:9a60] (rev 01)' = 9a60
      '';
    };

    # Compatibility Driver adjustments for older systems
    vaapiDriver = lib.mkOption {
      type = lib.types.str;
      default = "iHD";
      description = "VA-API driver name. Use 'iHD' for modern Intel chips.";
    };

    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GPU monitoring and diagnostic tools.";
    };

    # 32 Bit Graphics
    enable32Bit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable 32-bit graphics support (Required for Steam/Wine).";
    };

    # Legacy Graphics support
    enableLegacyVdpau = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the libvdpau-va-gl bridge.
        Useful for legacy applications that require VDPAU for hardware video acceleration instead of VA-API.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Failsafe Assertion
    # Pitfall prevented: If 'useXeDriver' is true but 'deviceId' is null, the string
    # interpolation below ("xe.force_probe=${cfg.deviceId}") will throw a cryptic Nix evaluation error.
    # This assertion stops the build immediately with a clear, human-readable error.
    assertions = [
      {
        assertion = !cfg.useXeDriver || cfg.deviceId != null;
        message = "mySystem.hardware.intel-gpu: 'deviceId' must be set when 'useXeDriver' is true.";
      }
    ];

    # --- KERNEL & DRIVER STACK ---
    boot.initrd.kernelModules = [ (if cfg.useXeDriver then "xe" else "i915") ];

    boot.kernelParams =
      if cfg.useXeDriver then
        [
          "i915.force_probe=!${cfg.deviceId}" # Tell i915 to NOT bind
          "xe.force_probe=${cfg.deviceId}" # Tell xe to bind
        ]
      else
        [
          # "GuC" (Graphics MicroController) and "HuC" (Header Unpack Control) firmware
          # for video acceleration on Gen12+ (Tiger Lake).
          "i915.enable_guc=3" # Enable GuC/HuC for offloading
          "i915.enable_fbc=1" # frame buffer compression
        ];

    # Allow the kernel to load necessary Intel binary blobs (GuC/HuC firmware).
    # This is even MORE critical for the xe driver than i915.
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # --- GRAPHICS FRAMEWORK ---
    hardware.graphics = {
      enable = true;
      enable32Bit = cfg.enable32Bit;

      extraPackages =
        with pkgs;
        [
          intel-media-driver # VA-API (iHD)
          vpl-gpu-rt # QuickSync Video (QSV)
          intel-compute-runtime # OpenCL / Level Zero (NEO)
          level-zero
        ]
        ++ lib.optional cfg.enableLegacyVdpau libvdpau-va-gl;

      # If 32-bit is enabled, we need the 32-bit versions of the drivers
      extraPackages32 = lib.mkIf cfg.enable32Bit (
        with pkgs.pkgsi686Linux;
        [
          intel-media-driver
        ]
        ++ lib.optional cfg.enableLegacyVdpau libvdpau-va-gl
      );

    };

    # --- ENVIRONMENT SETTINGS ---
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = cfg.vaapiDriver;
    }
    // lib.optionalAttrs cfg.enableLegacyVdpau {
      VDPAU_DRIVER = "va_gl";
    };

    environment.systemPackages =
      with pkgs;
      [
        # # GStreamer VA-API Plugin (For Linux Native Media Apps)
        gst_all_1.gst-vaapi
      ]
      ++ lib.optionals cfg.enableMonitoring (
        [
          # Standard Monitoring
          nvtopPackages.intel # nvtop

          # Verification Tools
          vulkan-tools # vulkaninfo
          libva-utils # vainfo (verifies video acceleration)
          mesa-demos # glxinfo (verifies OpenGL)
          clinfo # clinfo (Verifies OpenCL)
        ]
        # Legacy tools exclusively for the i915 driver
        ++ lib.optionals (!cfg.useXeDriver) [
          intel-gpu-tools # intel_gpu_top
        ]
      );
  };
}
