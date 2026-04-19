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
      viaProxy = false;
    };
    gpuDeviceId = "9a60";
  };

  ###
  ### Variable Imports
  ###
  browserSettings =
    (import ../../common/vars-browsers.nix {
      inherit appScaleFactor;
      dohEnable = mySettings.dnsOverHttps.enable;
      dohServer = mySettings.dnsOverHttps.url;
      dohCertPath = mySettings.dnsOverHttps.caCertPath;
    }).settings;

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
  boot.kernelPackages = pkgs.linuxPackages_latest.extend (
    lfinal: lprev: {
      # https://github.com/NixOS/nixpkgs/issues/490127
      opensnitch-ebpf =
        (pkgs-unstable.linuxPackages_latest.opensnitch-ebpf.override {
          # Force the unstable package to build against your current kernel tree
          kernel = lfinal.kernel;
        }).overrideAttrs
          (
            old:
            # Keep your existing workaround/assertion
            assert lib.versionOlder old.version "1.8.1";
            {
              preBuild = old.preBuild or "" + ''
                makeFlagsArray+=(EXTRA_FLAGS="-Wno-microsoft-anon-tag -fms-extensions")
              '';
            }
          );
    }
  );

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
      fuzzel # App launcher/Menu
      foot # Fast, Wayland-native terminal
      mako # Lightweight notification daemon
      libnotify # Provides 'notify-send'
      glib # Provides 'gsettings'

      waybar
      pkgs-unstable.ironbar
      pkgs-unstable.i3status-rust
      tofi
      wmenu
      pkgs-unstable.wl-clipboard
      cliphist
      grim
      slurp
      wf-recorder
      kanshi
      brightnessctl
      iwmenu
      libappindicator-gtk3
      #networkmanagerapplet
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
      inherit (browserSettings) scaling search preferences;
      inherit (browserSettings) security privacy ai;
      inherit (browserSettings) certificates;

      networking = browserSettings.networkingBlockWebRtc;
      hardware.graphics = browserSettings.hardwareGles.graphics;

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
  ### Browser: Chromium
  ###
  cytopia.programs.browsers.chromium = {
    enable = true;

    features = {
      inherit (browserSettings) scaling search preferences;
      inherit (browserSettings) security privacy ai;
      inherit (browserSettings) certificates;

      networking = browserSettings.networkingBlockWebRtc;
      hardware.graphics = browserSettings.hardwareVulkan.graphics;

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
      inherit (browserSettings) scaling search preferences;
      inherit (browserSettings) security privacy ai;
      inherit (browserSettings) certificates;

      networking = browserSettings.networkingAllowWebRtc;
      hardware.graphics = browserSettings.hardwareVulkan.graphics;

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
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "cytopia" ];
    };
  };

  services.opensnitch = {
    enable = true;
    package = pkgs-unstable.opensnitch;
    settings = {
      Firewall = "nftables";
      #ProcMonitorMethod = "proc"; # Fallback to /proc instead of compiling eBPF
    };
    rules =  opensnitchRules;
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
    lsof

    # Essentials
    git
    tmux
    gnumake

    # *.deb compatibility
    steam-run
  ];

  # Keep
  system.stateVersion = "25.11";
}
