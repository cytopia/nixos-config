{ config, pkgs, username, ... }:


{
  # TODO: what is this?
  programs.nix-ld.enable = true;


  imports =
  [
    ./hardware-configuration.nix
    #../../modules/nixos/default.nix

    # --- Core modules ---
    ./modules/core/network.nix
    #./modules/core/time-locale.nix
    #./modules/core/keyboard.nix
    #./modules/core/users.nix

    # NEW MODULES
    #./modules/core/gpu-intel.nix
    #./modules/core/bluetooth.nix
    ../../modules/nixos/hardware/gpu-intel.nix
    ../../modules/nixos/hardware/gpu-virtualbox.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/system/power-management.nix
    ../../modules/nixos/system/sound.nix
    ../../modules/nixos/system/keyboard.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/user.nix

    #./modules/core/sound.nix
    #./modules/core/power-management.nix

    # --- CLI modules ---
    ./modules/cli/vim.nix

    # --- GUI modules ---
    ./modules/gui/fonts.nix
    ./modules/gui/login-manager.nix
    ./modules/gui/display-manager.nix
    ./modules/gui/sway.nix

    # --- Programs ---
    ./modules/programs/_default.nix
    ./modules/programs/chromium.nix
    ./modules/programs/thunar.nix
    ./modules/programs/podman.nix
    ./modules/programs/obs.nix
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
  mySystem.system.power-management = {
    enable = true;
  };
  mySystem.system.sound = {
    enable = true;
    supportBluetooth = true;
    enableLowLatency = false;
  };
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
  mySystem.system.user = {
    enable = true;
    name = username;
    uid = 1000;
    homeMode = "0700";
  };

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

  environment.systemPackages = [
    pkgs.steam-run
  ];
  qt.enable = true;

  # Might help chromium errors and screensharing
  fonts.fontconfig.enable = true;


  system.stateVersion = "25.11"; # Did you read the comment?
}

