{ config, pkgs, username, ... }:


{
  # TODO: what is this?
  programs.nix-ld.enable = true;


  imports =
  [
    # Hardware
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/gpu-intel.nix
    ../../modules/nixos/hardware/gpu-virtualbox.nix
    ../../modules/nixos/hardware/bluetooth.nix

    # System
    ../../modules/nixos/system/keyboard.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/user.nix
    ../../modules/nixos/system/fonts.nix

    # Services
    ../../modules/nixos/services/power-management.nix
    ../../modules/nixos/services/sound.nix
    ../../modules/nixos/services/login.nix

    # --- deprecated stuff to migrate

    # --- Core modules ---
    ./modules/core/network.nix

    # --- CLI modules ---
    ./modules/cli/vim.nix

    # --- GUI modules ---
    #./modules/gui/login-manager.nix
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
	gnomeKeyring.enable = true;
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

