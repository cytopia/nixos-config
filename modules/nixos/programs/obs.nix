{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.programs.obs;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio with Virtual Camera support";

    cameraLabel = lib.mkOption {
      type = lib.types.str;
      default = "USB Video Device";
      description = ''
        The name of the virtual camera as it appears in apps like Zoom/Teams.
        Use "Integrated Webcam" or "USB Video Device" to mimic hardware.
      '';
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # --- THE SYSTEM-WIDE MODULE ---
    programs.obs-studio = {
      enable = true;

      # Virtual Camera Infrastructure
      # This single line handles the 'v4l2loopback' kernel module and
      # the necessary suid/wrapper logic automatically.
      enableVirtualCamera = true;

      # PLUGIN CONSOLIDATION
      # These are installed system-wide and made available to the OBS binary.
      # https://mynixos.com/search?q=obs-studio-plugins
      plugins = with pkgs.obs-studio-plugins; [
        # --- CORE CAPTURE ---
        wlrobs                      # Sway standard - wlroot
        obs-pipewire-audio-capture  # essential for PipeWire/Wayland
        obs-vkcapture               # High-perf gaming/3D capture

        # --- INFRASTRUCTURE & ENCODING ---
        obs-gstreamer
        obs-vaapi               # Dedicated HW encoding for Intel/AMD

        # --- WORKFLOW & AUTOMATION ---
        advanced-scene-switcher # "Senior" automation logic
        obs-move-transition     # Aesthetic "Smooth" scene changes

        # --- UTILITY & SECURITY ---
        obs-composite-blur      # Masking sensitive info/keys
        obs-backgroundremoval   # Clean webcam look
        obs-source-record       # Record raw footage while streaming
      ];
    };

    # We load the module at boot so the device is ALWAYS available,
    # even if OBS isn't open yet. This prevents apps from "forgetting"
    # your camera settings.
    boot.kernelModules = [ "v4l2loopback" ];

    # card_label="Integrated Webcam": This is the most "boring" and common name possible.
    # Most apps will treat this as the built-in camera on a laptop.
    # If you want to look like an external high-end camera, you could use "Logitech USB Camera".
    #
    # exclusive_caps=1: This hides the "Output" capability. To an app like Chrome,
    # the device looks identical to a standard hardware UVC (USB Video Class) camera.
    #
    # max_buffers=2: Hardware cameras have very small internal buffers to keep latency low.
    # Virtual cameras sometimes default to larger buffers, which can cause a "laggy" look.
    # Setting this to 2 forces the virtual camera to behave with the same snappiness as physical hardware.
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="${cfg.cameraLabel}" exclusive_caps=1 max_buffers=2
    '';

    # --- HARDWARE ACCESS ---
    # ADDITION: Ensure the user has permission to access video devices
    # without needing to be root.
    # users.groups.video.members = config.mySystem.users; # Assuming you have a list of users
    # users.users.${config.mySystem.user}.extraGroups = [ "video" ];
  };
}
