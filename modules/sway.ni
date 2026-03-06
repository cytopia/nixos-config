{ config, pkgs, ... }:


let
{
  ###
  ### Graphics
  ###
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VA-API (iHD) userspace
      vpl-gpu-rt          # oneVPL (QSV) runtime
      # Optional (compute / tooling)
      intel-compute-runtime # OpenCL (NEO) + Level ero for Arc/Xe
      vulkan-loader

      libva-utils
      libvdpau-va-gl
    ];
  };


  ###
  ### Sound
  ###
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # High-priority scheduling for real-time audio (low-latency)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;  # modern default session manager
  };


  ###
  ### Keyboard
  ###
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  # Adjust keyboard rate
  systemd.services.set-kdb-rate = {
    description = "Set the keyboard repeat rate";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 250 -r 50";
    };
  };


  ###
  ### Login Manager
  ###
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # -t: time, -r: Remember last user, -c: Command to run
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --cmd sway";
        user = "greeter";
        vt = 1;
      };
    };
  };

  # Keep the TUI clean from kernel "noise" during password entering on greetd
  boot.kernelParams = [ "quiet" "splash" ];


  ###
  ### Wayland / Xserver
  ###

  # Configure keymap in X11/Wayland
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Security: ensure we aren't pulling X11 auth/socket plumbing
  services.xserver.enable = false;

  # XDG Desktop Portal framework.
  # It’s a standardized way for applications to request "privileges" from the desktop environmen
  # Without it, things like file pickers, screen sharing, and "Open File" dialogs often break
  # or look like they’re from 1995.
  xdg.portal = {
    enable = true;
    wlr.enable = true;  # screensharing via Pipewire
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*"; # modern xdg-desktop-portal 1.17+ syntax
  };

  # Necessary for screen sharing (Pipewire/XDG portals)
  services.dbus.enable = true;


  ###
  ### Sway
  ###
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # necessary for GTK app scaling/theming
    #extraOptions = [ "--unsupported-gpu" ];  # only if using nvidia
    extraPackages = with pkgs; [
      swaylock-effects
      swayidle
      waybar
      foot
      procps
      # run client
      wmenu
      fuzzel
      tofi
      # clipboard
      wl-clipboard
      cliphist      # clipboard history manager
      # notifications
      swaynotificationcenter
      mako
      libnotify
      # screenshots
      grim
      slurp
      # screen recording
      wf-recorder
      # brightness control
      brightnessctl
      # external screens
      kanshi
      # wifi control
      iwmenu
    ];
  };

  environment.systemPackages = with pkgs; [
    slurp # Required for screen sharing region/output
    papirus-icon-theme
  ]

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.symbols-only
  ];

  environment.sessionVariables = {
    # --- General Session ---
    XDG_SESSION_TYPE            = "wayland";
    XDG_CURRENT_DESKTOP         = "sway";
    XDG_SESSION_DESKTOP         = "sway";

    # --- GTK (Gnome-based apps) ---
    GDK_BACKEND                 = "wayland";

    # --- QT (KDE/OBS/vlc) ---
    # Tells QT to use the wayland platform plugin
    QT_QPA_PLATFORM             = "wayland";
    # Prevents issues with window decoration in some apps
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # Enables automatic HiDPI scaling for QT
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";

    # --- Electrom & Chromium ---
    NIXOS_OZONE_WL              = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # --- Firefox ---
    MOZ_ENABLE_WAYLAND          = "1";

    # --- SDL (Games & Emulators) ---
    # Tells Games using the SDL2 library to use Wayland
    SDL_VIDEODRIVER             = "wayland";

    # --- Clutter ---
    CLUTTER_BACKEND             = "wayland";

    # --- Java ---
    # Fixes gray screen issues
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # Enable native wayland toolkit
    JAVA_TOOL_OPTIONS           = "-Dawt.toolkit.name=WLToolkit";

    # --- Hardware acceleration (Intel/AMD) ---
    # Ensures hardware video dcoding using Wayland-native buffers
    LIBVA_DRIVER_NAME           = "iHD"; # Use "iHD" for Intel, "radeonsi" for AMD
  };
}
