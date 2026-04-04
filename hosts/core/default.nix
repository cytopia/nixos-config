{
  pkgs,
  pkgs-unstable,
  hostname,
  username,
  appScaleFactor,
  ...
}:
let

  dnscryptLocalDoh = {
    enable = true;
    port = 3000;
    path = "/dns-query";
    caCertPath = "/run/local-doh-ca/rootCA.pem";
  };

  bowserSettingsWithLocalDoh = {
    extraPolicies =
      if dnscryptLocalDoh.enable then
        {
          "BuiltInDnsClientEnabled" = true;
          "AdditionalDnsQueryTypesEnabled" = true;
          "EncryptedClientHelloEnabled" = true;
          # Enable Secure DNS (DoH) so Chromium trusts the connection and enables ECH.
          "DnsOverHttpsMode" = "secure";

          # Point Chromium strictly to our local dnscrypt-proxy instance using the TLS cert.
          "DnsOverHttpsTemplates" = "https://localhost:${toString dnscryptLocalDoh.port}${dnscryptLocalDoh.path}";

          # Bypass DoH for internal/VPN domains.
          # Chromium will send these to systemd-resolved (plaintext), which will correctly route them to the VPN's nameserver.
          "DnsOverHttpsExcludedDomains" = [
            "*.local" # mDNS local domains
            "*.internal" # Common internal networks
          ];
        }
      else
        { };
    customCaCerts =
      if dnscryptLocalDoh.enable then
        [
          {
            name = "dnscrypt-proxy";
            path = dnscryptLocalDoh.caCertPath;
          }
        ]
      else
        [ ];
  };

in
{
  imports = [
    # NixOS hardware config: sudo nixos-generate-config
    ./hardware-configuration.nix
    ./disko-config.nix
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
    # Networking
    ../../modules/nixos/networking/services/ntp.nix
    ../../modules/nixos/networking/services/dns.nix
    ../../modules/nixos/networking/simple.nix
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
    ../../modules/nixos/programs/podman.nix
    ../../modules/nixos/programs/vim.nix
    ../../modules/nixos/programs/chromium.nix
    ../../modules/nixos/programs/google-chrome.nix
    # Utils
    ../../modules/nixos/utils/camera-toggle.nix
  ];

  ###
  ### Kernel
  ###
  boot.kernelPackages = pkgs.linuxPackages_latest;

  ###
  ### Booting (ensure aesni_intel and crypd kernel mods are loaded)
  ###

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable LVM in the initrd so it can find the encrypted partition at boot.
  # Disko created the LVM and NixOS needs to scan for it at boot.
  boot.initrd.services.lvm.enable = true;

  # Activate swap (disko defined it)
  # Disko defines the partition and NixOS needs this to run 'swapon' at boot.
  #  swapDevices = [ { device = "/dev/mapper/pool-swap"; } ];
  #  boot.resumeDevice = "/dev/mapper/pool-swap";

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
      "wheel" # Sudo privileges
      "networkmanager" # WiFi/Network control
      #"podman"          # For podman if enabling docker socket (security issue)
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
  mySystem.networking.service.ntp.enable = true;
  mySystem.networking.service.dns = {
    enable = true;
    query = {
      #protocol = "dnscrypt-ecs";
      protocol = "doh";
      http3 = true;
      ipv6 = false;
      #viaProxy = true;
      viaProxy = false;
    };

    # Enable local DoH server (see let..in for options)
    localDoh = dnscryptLocalDoh;

    localBlockList = {
      enable = true;
      urls = [
        "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
        "https://v.firebog.net/hosts/static/w3kbl.txt"
        "https://adaway.org/hosts.txt"
        "https://v.firebog.net/hosts/AdguardDNS.txt"
        "https://v.firebog.net/hosts/Admiral.txt"
        "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
        "https://v.firebog.net/hosts/Easylist.txt"
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
        "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
        "https://v.firebog.net/hosts/Easyprivacy.txt"
        "https://v.firebog.net/hosts/Prigent-Ads.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
        "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
        "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
        "https://download.dnscrypt.info/blacklists/domains/mybase.txt"
      ];
    };
    whitelist = [
      "ip-api.com"
    ];
    localMonitoring = {
      enable = true;
      port = 4400;
    };
  };
  #services.opensnitch.enable = true;

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
      #sway-audio-idle-inhibit
      #swaynotificationcenter
    ];
  };

  ###
  ### My Modules: Programs
  ###
  mySystem.programs.thunar.enable = true;
  mySystem.programs.obs.enable = true;
  mySystem.programs.podman.enable = true;
  mySystem.programs.vim.enable = true;

  mySystem.programs.chromium = {
    enable = true;
    browser = "chromium";
    scalingFactor = appScaleFactor;
    waylandFractionalScalingSupport = true;
    gpu.engine.displayServer = "wayland";

    # Ensure all Vulkan layers (e.g. OBS are removed)
    startup.extraEnvVars = {
      "VK_LOADER_LAYERS_DISABLE" = "VK_LAYER_OBS_vkcapture_32,VK_LAYER_OBS_vkcapture_64";
    };
    # Use dnscrypt-proxy as a local DoH resolver?
    extraPolicies = bowserSettingsWithLocalDoh.extraPolicies;
    customCaCerts = bowserSettingsWithLocalDoh.customCaCerts;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "ckkdlimhmcjmikdlpkmbgfkaikojcbjk" # Markdown Viewer
      "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube
      "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
    ];
  };

  mySystem.programs.google-chrome = {
    enable = true;
    browser = "google-chrome";
    scalingFactor = appScaleFactor;
    waylandFractionalScalingSupport = true;
    gpu.engine.displayServer = "wayland";

    # Ensure all Vulkan layers (e.g. OBS are removed)
    startup.extraEnvVars = {
      "VK_LOADER_LAYERS_DISABLE" = "VK_LAYER_OBS_vkcapture_32,VK_LAYER_OBS_vkcapture_64";
    };
    # Use dnscrypt-proxy as a local DoH resolver?
    extraPolicies = bowserSettingsWithLocalDoh.extraPolicies;
    customCaCerts = bowserSettingsWithLocalDoh.customCaCerts;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "jpmkfafbacpgapdghgdpembnojdlgkdl" # AWS Extend Roles
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
    ];
  };

  ###
  ### My Modules: Utils
  ###
  mySystem.utils.camera-toggle = {
    enable = true;
    userName = username;
  };

  # Adds standard Linux paths
  # e.g. /lib64 and others
  # TODO: double-check if this is currently required
  programs.nix-ld.enable = true;

  # TODO: Move this somewhere else
  programs.awsvpnclient.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "cytopia" ];
    };
  };

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
