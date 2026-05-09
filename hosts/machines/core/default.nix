{
  lib,
  pkgs,
  pkgs-unstable,
  hostname,
  username,
  appScaleFactor,
  ...
}:
let

  ###
  ### Global Settings
  ###
  mySettings = {
    dnsOverHttps = rec {
      enable = true;
      host = "127.0.0.1";
      port = 3000;
      path = "/dns-query";
      caCertPath = "/run/local-doh-ca/rootCA.pem";
      url = "https://${host}:${toString port}${path}";
    };
    dnsQuery = {
      protocol = "dnscrypt";
      viaProxy = true;
      timeout = 2000;
      lbStrategy = "p3";
    };
    gpuDeviceId = "9a60";
  };

  dnscryptSettings =
    (import ../../common/vars-dnscrypt-proxy.nix {
      dnscryptQuery = mySettings.dnsQuery;
      dnscryptLocalDoh = {
        inherit (mySettings.dnsOverHttps) enable port path;
      };
    }).settings;

  opensnitchRules =
    (import ../../common/vars-opensnitch-rules.nix {
      inherit lib;
      rulePrefix = "a"; # adjust to reimport all rules
      enableBrave = true;
      enableChrome = true;
      enableChromium = true;
      uid = 1000;
    }).rules;

in
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../../modules/nixos/default.nix
  ];

  ###
  ### Kernel
  ###

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;
  boot.kernelPackages = pkgs.linuxPackages_zen;

  ###
  ### Booting (ensure aesni_intel and crypd kernel mods are loaded)
  ###

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable LVM in the initrd so it can find the encrypted partition at boot.
  # Disko created the LVM and NixOS needs to scan for it at boot.
  boot.initrd.services.lvm.enable = true;

  # Better SSD lifespan with encryption (comes with a security risk)
  boot.initrd.luks.devices."crypted".allowDiscards = true;

  ###
  ### My Modules: Hardware
  ###
  mySystem.hardware.intel-gpu = {
    enable = true;
    enable32Bit = false;
    enableMonitoring = true;
    useXeDriver = true;
    deviceId = mySettings.gpuDeviceId;
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
      LC_MEASUREMENT = "de_DE.UTF-8"; # Metric System
    };
  };
  mySystem.system.fonts = {
    enable = true;
    fontChoice = "jetbrains";
  };
  mySystem.system.user = {
    enable = true;
    name = username;
    uid = 1000;
    homeMode = "0700";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  mySystem.system.keyring = {
    enable = true;
    gnomeKeyringEnable = true;
  };

  ###
  ### My Modules: Networking
  ###
  mySystem.networking.simple = {
    enable = true;
    hostName = hostname;
  };
  cytopia.service.ntp = {
    enable = true;
    firewall.enable = true;
  };
  cytopia.service.dns = {
    enable = true;
    firewall.enable = true;
    # How to Query DNS
    inherit (dnscryptSettings) query;
    # Local DNS over Https Server
    inherit (dnscryptSettings) localDoh certs;
    # Misc
    inherit (dnscryptSettings) localMonitoring;
    inherit (dnscryptSettings) localBlockList whitelist;
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
    enableXwayland = true;
    # You can append more packages here if needed
    extraPackages = with pkgs; [
      swaylock-effects # Screen locker (Base PAM service in wayland.nix)
      swayidle # Idle management daemon
      sway-audio-idle-inhibit # Prevent sleep whenever audio is played
      foot # Fast, Wayland-native terminal
      glib # Provides 'gsettings'

      grim
      wf-recorder
      kanshi
      brightnessctl
      iwmenu
      # Tools
      slurp  # Region selector for wayland compositor
      wlprop
      swaytools  # Provides 'swayinfo'
      # Clipboard
      wl-clipboard
      cliphist
      # Notifications
      mako # Lightweight notification daemon
      libnotify # Provides 'notify-send'
      # Launcher
      fuzzel # App launcher/Menu
      tofi
      wmenu
      # Bar / Applets
      ironbar
      i3status-rust
      waybar
      libappindicator-gtk3
      blueman
    ];
  };

  ###
  ### My Modules: Programs
  ###
  mySystem.programs.thunar.enable = true;
  mySystem.programs.obs.enable = true;
  mySystem.programs.podman.enable = true;
  mySystem.programs.vim.enable = true;

  ###
  ### Browser: Brave
  ###
  cytopia.programs.browsers.brave = {
    enable = true;

    features = {
      # Hardware Acceleration
      hardware.graphics.backend = "vulkan";
      hardware.graphics.disabledVulkanLayers = [
        "VK_LAYER_OBS_vkcapture_32"
        "VK_LAYER_OBS_vkcapture_64"
      ];
      # Scaling
      scaling.factor = appScaleFactor;
      scaling.waylandFractionalScaling = true;
      # DNS
      networking.dns.enableBuiltInDns = mySettings.dnsOverHttps.enable;
      networking.dns.doh.enable = mySettings.dnsOverHttps.enable;
      networking.dns.doh.template = mySettings.dnsOverHttps.url;
      # SSL Certiciate for DNS over HTTPS server
      certificates.customCaCerts = [
        {
          name = "dnscrypt-proxy";
          path = mySettings.dnsOverHttps.caCertPath;
        }
      ];
      extensions.forceInstall = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "ckkdlimhmcjmikdlpkmbgfkaikojcbjk" # Markdown Viewer
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
        "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
        "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
      ];
    };
  };

  ###
  ### Browser: Chromium
  ###
  cytopia.programs.browsers.chromium = {
    enable = true;

    features = {
      # Hardware Acceleration
      hardware.graphics.backend = "vulkan";
      hardware.graphics.disabledVulkanLayers = [
        "VK_LAYER_OBS_vkcapture_32"
        "VK_LAYER_OBS_vkcapture_64"
      ];
      # Scaling
      scaling.factor = appScaleFactor;
      scaling.waylandFractionalScaling = true;
      # DNS
      networking.dns.enableBuiltInDns = mySettings.dnsOverHttps.enable;
      networking.dns.doh.enable = mySettings.dnsOverHttps.enable;
      networking.dns.doh.template = mySettings.dnsOverHttps.url;
      # SSL Certiciate for DNS over HTTPS server
      certificates.customCaCerts = [
        {
          name = "dnscrypt-proxy";
          path = mySettings.dnsOverHttps.caCertPath;
        }
      ];
      extensions.forceInstall = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "ckkdlimhmcjmikdlpkmbgfkaikojcbjk" # Markdown Viewer
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
        "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
      ];
    };
  };

  ###
  ### Browser: Google Chrome
  ###
  cytopia.programs.browsers.google-chrome = {
    enable = true;

    features = {
      # Hardware Acceleration
      hardware.graphics.backend = "gles";
      hardware.graphics.hideVulkanLoader = true;
      hardware.graphics.disabledVulkanLayers = [
        "VK_LAYER_OBS_vkcapture_32"
        "VK_LAYER_OBS_vkcapture_64"
      ];
      # Scaling
      scaling.factor = appScaleFactor;
      scaling.waylandFractionalScaling = true;
      # Privacy settings
      privacy.webTracking.stripReferrers = false;
      # WebRTC
      networking.webrtc.preventIpLeaks = false;
      # DNS
      networking.dns.enableBuiltInDns = mySettings.dnsOverHttps.enable;
      networking.dns.doh.enable = mySettings.dnsOverHttps.enable;
      networking.dns.doh.template = mySettings.dnsOverHttps.url;
      # SSL Certiciate for DNS over HTTPS server
      certificates.customCaCerts = [
        {
          name = "dnscrypt-proxy";
          path = mySettings.dnsOverHttps.caCertPath;
        }
      ];

      extensions.forceInstall = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "jpmkfafbacpgapdghgdpembnojdlgkdl" # AWS Extend Roles
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      ];
    };
  };

  mySystem.programs.thunderbird = {
    enable = true;
    dnsOverHttps = {
      inherit (mySettings.dnsOverHttps) enable url caCertPath;
    };
  };

  ###
  ### My Modules: Utils
  ###
  mySystem.utils.camera-toggle = {
    enable = true;
    userName = username;
  };

  # Enable the OpenSSH daemon.
  #services.openssh = {
  #  enable = true;
  #  settings = {
  #    PasswordAuthentication = true;
  #    AllowUsers = [ "cytopia" ];
  #  };
  #};

  services.opensnitch = {
    enable = true;
    package = pkgs-unstable.opensnitch;
    settings = {
      Firewall = "nftables";
    };
    rules = opensnitchRules;
  };

  ###
  ### Standard System packages
  ###

  # Adds standard Linux paths
  # e.g. /lib64 and others
  programs.nix-ld.enable = true;

  # AWS VPN Client
  programs.awsvpnclient.enable = true;

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
    tree
    # Disk
    parted
    lsof
    util-linux
    xfsprogs
    e2fsprogs

    # Essentials
    git
    tmux
    gnumake
    jq
    yq-go

    # *.deb compatibility
    steam-run
  ];

  # Keep
  system.stateVersion = "25.11";
}
