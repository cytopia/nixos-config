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
    #caCertPath = "/run/local-doh-ca/rootCA.pem";
  };
  dnscryptCerts = {
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
          "DnsOverHttpsTemplates" =
            "https://127.0.0.1:${toString dnscryptLocalDoh.port}${dnscryptLocalDoh.path}";

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
            path = dnscryptCerts.caCertPath;
          }
        ]
      else
        [ ];
  };

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
  cytopia.service.ntp = {
    enable = true;
    firewall.enable = true;
  };
  cytopia.service.dns = {
    enable = true;
    firewall.enable = true;
    query = {
      protocol = "dnscrypt-ecs";
      #protocol = "doh";
      http3 = true;
      ipv6 = false;
      viaProxy = true;
      #viaProxy = false;
    };
    certs = dnscryptCerts;

    # Enable local DoH server (see let..in for options)
    localDoh = dnscryptLocalDoh;

    localBlockList = {
      enable = true;
      urls = [
        # Info at https://firebog.net/
        "https://download.dnscrypt.info/blacklists/domains/mybase.txt"
        "https://v.firebog.net/hosts/AdguardDNS.txt"
        "https://v.firebog.net/hosts/Admiral.txt"
        "https://v.firebog.net/hosts/Easylist.txt"
        "https://v.firebog.net/hosts/Easyprivacy.txt"
        "https://v.firebog.net/hosts/Prigent-Ads.txt"
        "https://v.firebog.net/hosts/static/w3kbl.txt"
        "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
        "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
        "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
        "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
        "https://adaway.org/hosts.txt"
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
        "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
      ];
    };
    whitelist = [
      "ip-api.com"
      "ogads-pa.clients6.google.com"
      "csi.gstatic.com"
      "mail-ads.google.com"
    ];
    localMonitoring = {
      enable = true;
      port = 4400;
    };
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

  cytopia.programs.browsers.brave = {
    enable = true;
    features.scaling = {
      factor = appScaleFactor;
      waylandFractionalScaling = true;
    };
  };

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
    gpu.engine.backend = "gl";

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

  mySystem.programs.thunderbird = {
    enable = true;

    dnsOverHttps = {
      enable = dnscryptLocalDoh.enable;
      url = "https://127.0.0.1:${toString dnscryptLocalDoh.port}${dnscryptLocalDoh.path}";
      caCertPath = dnscryptCerts.caCertPath;
    };
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
