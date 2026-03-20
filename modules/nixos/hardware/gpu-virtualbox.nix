{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.hardware.virtualbox-gpu;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.hardware.virtualbox-gpu = {
    enable = lib.mkEnableOption "VirtualBox Guest Graphics Support";

    waylandSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable fixes for Wayland (Sway/Hyprland) in VirtualBox (e.g., cursor fixes).";
    };

    enable32Bit = lib.mkOption {
      type = lib.types.bool;
      default = false; # Lean by default
      description = "Enable 32-bit graphics support. Usually unnecessary in a VM unless running old games/apps.";
    };

    # Adds a specific option for GLES2.
    # Reason: Full Desktop OpenGL is often too heavy/broken for VMSVGA.
    # OpenGL ES 2.0 is the "sweet spot" for VM performance.
    forceGLES2 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Force the use of GLES2 renderer. Usually much faster than default GL in a VM.";
    };

    forceSoftwareRenderer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force software rendering (pixman). Use ONLY if the screen is flickering or black.";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- KERNEL & GUEST SERVICES ---

    #  CORE: Loads kernel modules (vboxguest, vboxsf, vboxvideo)
    virtualisation.virtualbox.guest.enable = true;

    # DRIVER: Overwrite the driver to use the VMSVGA-optimized 'vmware' driver.
    # By placing this after/with the x11 toggle, we ensure we use the best renderer.
    services.xserver.videoDrivers = [ "vmware" ];


    # --- GRAPHICS FRAMEWORK ---
    hardware.graphics = {
      enable = true;
      enable32Bit = cfg.enable32Bit;
    };


    # --- ENVIRONMENT SETTINGS ---
    environment.sessionVariables = {
      # Fixes the 'invisible cursor' issue in Sway/Hyprland on VirtualBox
      WLR_NO_HARDWARE_CURSORS = lib.mkIf cfg.waylandSupport "1";

      # Atomic Mode Setting Disable
      # Pitfall prevented: VirtualBox's driver often fails the "Atomic" check,
      # causing laggy frame-pacing. Disabling it smooths out the UI.
      WLR_DRM_NO_ATOMIC = lib.mkIf cfg.waylandSupport "1";

      # The "Safety Net": Allows a slow desktop instead of a crash if 3D fails.
      WLR_RENDERER_ALLOW_SOFTWARE = lib.mkIf cfg.waylandSupport "1";

      # Renderer Selection
      # We force 'gles2' instead of letting it struggle with full GL.
      # If 'forceSoftwareRenderer' is on, 'pixman' takes priority.
      WLR_RENDERER = lib.mkIf cfg.waylandSupport (lib.mkForce (
        if cfg.forceSoftwareRenderer then "pixman"
        else if cfg.forceGLES2 then "gles2"
        else "auto"
      ));
    };


    # --- TOOLS & DIAGNOSTICS ---
    environment.systemPackages = with pkgs; [
      vulkan-tools
      mesa-demos
    ];
  };
}
