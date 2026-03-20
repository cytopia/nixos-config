{ config, pkgs, pkgs-unstable, username, ... }:


{
  imports =
  [
    # NixOS hardware config: sudo nixos-generate-config
    ./hardware-configuration.nix
    # Hardware
    ../../modules/nixos/hardware/gpu-intel.nix
    ../../modules/nixos/hardware/gpu-virtualbox.nix
    ../../modules/nixos/hardware/bluetooth.nix
    # System
    ../../modules/nixos/system/keyboard.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/fonts.nix
    ../../modules/nixos/system/user.nix
    ../../modules/nixos/system/keyring.nix
    # Services
    ../../modules/nixos/services/power-management.nix
    ../../modules/nixos/services/sound.nix
    ../../modules/nixos/services/login.nix
    # Desktop
    ../../modules/nixos/desktop/wayland.nix
    ../../modules/nixos/desktop/sway.nix
    # Programs
    ../../modules/nixos/programs/thunar.nix
    ../../modules/nixos/programs/obs.nix


    # --- deprecated stuff to migrate

    # --- Core modules ---
    ./modules/core/network.nix

    # --- CLI modules ---
    ./modules/cli/vim.nix

    # --- Programs ---
    #./modules/programs/_default.nix
    ./modules/programs/chromium.nix
    ./modules/programs/podman.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  ###
  ### My Modules: Hardware
  ###
  mySystem.hardware.intel-gpu = {
    enable = true;
    enable32Bit = false;
    enableMonitoring = true;
    useXeDriver = true;
    deviceId = "9a60";
  };
  mySystem.hardware.bluetooth = {
    enable = true;
    enableGUI = true;
  };


  ###
  ### My Modules: System
  ###
  mySystem.system.keyboard = {
    enable = true;
    repeatDelay = "250";
    repeatRate = "50.0";
  };
  mySystem.system.locale = {
    enable = true;
    timeZone = "Europe/Berlin";
    defaultLocale = "en_US.UTF-8";
    extraConfig = {
      LC_MEASUREMENT = "de_DE.UTF-8";  # Metric System
    };
  };
  mySystem.system.fonts = {
    enable = true;
  };
  mySystem.system.user = {
    enable = true;
    name = username;
    uid = 1000;
    homeMode = "0700";
  };
  mySystem.system.keyring = {
    enable = true;
    keyringEnable = true;
  };


  ###
  ### My Modules: Services
  ###
  mySystem.services.power-management = {
    enable = true;
  };
  mySystem.services.sound = {
    enable = true;
    supportBluetooth = true;
    enableLowLatency = false;
  };
  mySystem.services.login = {
    enable = true;
    defaultSession = "sway";
  };


  ###
  ### My Modules: Desktop
  ###
  mySystem.desktop.sway = {
    enable = true;
    terminal = "foot";
    # You can append more packages here if needed
    extraPackages = with pkgs; [
      swaylock-effects  # Screen locker (Base PAM service in wayland.nix)
      swayidle          # Idle management daemon
      fuzzel            # App launcher/Menu
      foot              # Fast, Wayland-native terminal
      mako              # Lightweight notification daemon
      libnotify         # Provides 'notify-send'

      waybar
      pkgs-unstable.ironbar
      pkgs-unstable.i3status-rust
      tofi
      wmenu
      wl-clipboard
      cliphist
      grim
      slurp
      wf-recorder
      kanshi
      brightnessctl
      iwmenu
      libappindicator-gtk3
      networkmanagerapplet
      blueman
      #sway-audio-idle-inhibit
      #swaynotificationcenter
    ];
  };


  ###
  ### My Modules: Programs
  ###
  mySystem.programs.thunar.enable = true;
  mySystem.programs.obs.enable = true;



  # TODO: what is this?
  programs.nix-ld.enable = true;




  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "cytopia" ];
    };
  };



  # TODO: Move this somewhere else
  programs.awsvpnclient.enable = true;


  ###
  ### Standard System packages
  ###
  environment.systemPackages = with pkgs; [
    # Utilities
    pciutils
    usbutils
    unzip
    zip
    file
    procps
    killall
    unixtools.netstat
    unixtools.ifconfig
    curl
    wget
    dig

    # Essentials
    vim
    git
    tmux
    gnumake
    #fastfetch

    # *.deb compatibility
    steam-run
  ];

  # Keep
  system.stateVersion = "25.11";
}

