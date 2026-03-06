{ config, pkgs, ... }:


{
  ###
  ### Kernel Settings
  ###

   # 1. Enable Guest Additions (Drivers for video, mouse, and shared folders)
  virtualisation.virtualbox.guest.enable = true;

  # 2. Tell NixOS to use the VirtualBox/VMware video driver
  # VMSVGA uses the 'vmware' driver under the hood in Linux.
  services.xserver.videoDrivers = [ "vmware" ];

  # 3. Required for Wayland/Sway in VirtualBox
  # This ensures the virtualized 3D acceleration is active.
  hardware.graphics = {
    enable = true;
  };

  ###
  ### Environment Variables
  ###
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes invisible cursor in Sway/Hyprland
    WLR_RENDERER_ALLOW_SOFTWARE = "1"; # Fallback if 3D acceleration fails
    # This forces Sway to use a stable rendering path that ignores the "broken" driver check
    WLR_RENDERER = "pixman";
  };

  ###
  ### Additional GPU Monitoring & Info Tools
  ###
  environment.systemPackages = with pkgs; [
    vulkan-tools           # Provides 'vulkaninfo'
    libva-utils            # Provides 'vainfo' (verifies video acceleration)
    mesa-demos             # Provides 'glxinfo' (verifies OpenGL)
    clinfo                 # Verifies OpenCL (intel-compute-runtime)
  ];
}
