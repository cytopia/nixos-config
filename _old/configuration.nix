# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:


let
  myWaylandFlags = [
    "--ozone-platform=wayland"
    "--ozone-platform-hint=auto"
    "--enabe-features=TouchpadOverscrollHistoryNavigation,WaylandWindowDecorations"
    "--enable-wayland-ime"
    # Fix: GL
    "--use-gl=angle"
    "--use-angle=gles"
    # Vulkan (breaks video encoding)
    #"--use-angle=vulkan"
    "--enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workarounds"
    # Fix: Video encoding
    "--enable-features=AcceleratedVideoEncoder"
    "--enable-zero-copy"
    # Enables GPU rasterization on all pages
    "--enable-gpu-rasterization"
    # Enable TreesInViz (breaks video encoding)
    #"--enable-features=TreesInViz"

  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VA-API (iHD) userspace
      vpl-gpu-rt          # oneVPL (QSV) runtime
      # Optional (compute / tooling)
      intel-compute-runtime # OpenCL (NEO) + Level ero for Arc/Xe
      vulkan-loader

      libvdpau-va-gl
    ];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep the TUI clean from kerne "noise" during password entering on greetd
  boot.kernelParams = [ "quiet" "splash" ];

  boot.initrd.luks.devices."luks-d9097b1c-d54a-4659-89c9-9393df8e0b2a".device = "/dev/disk/by-uuid/d9097b1c-d54a-4659-89c9-9393df8e0b2a";


  networking.hostName = "nixos"; # Define your hostname.

  # Modern wireless way
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = false;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";


  # Enable networking

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  systemd.services.set-kdb-rate = {
    description = "Set the keyboard repeat rate";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 250 -r 50";
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };


  ###
  ### Sound
  ###
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # Realtime Kit (for low latency)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };



  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cytopia = {
    isNormalUser = true;
    description = "cytopia";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (self: super: {
      ungoogled-chromium = super.ungoogled-chromium.override {
        commandLineArgs = myWaylandFlags;
      };
    })
  ];


  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Required for screen locking (System level only)
  security.pam.services.swaylock = {};



  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # necessary for GTK app scaling/theming
    #extraOptions = [ "--unsupported-gpu" ];  # only if using nvidia
    extraPackages = with pkgs; [
      swaylock-effects
      swayidle
    ];
  };
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

    # ZSH
    ZDOTDIR = ''$HOME/.config/zsh'';
  };


  # Security: ensure we aren't pulling X11 auth/socket plumbing
  services.xserver.enable = false;

  # Necessary for screen sharing (Pipewire/XDG portals)
  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*"; # modern xdg-desktop-portal 1.17+ syntax
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.symbols-only
  ];



  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    foot
    waybar
    fuzzel
    swaynotificationcenter
    wl-clipboard
    vim
    cliphist
    mako
    grim
    slurp
    wf-recorder
    ungoogled-chromium
    libva-utils
    thunderbird
    fuzzel
    tofi
    kanshi
    wmenu
    brightnessctl
    tmux
    libnotify
    papirus-icon-theme
    iwmenu
    procps
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
