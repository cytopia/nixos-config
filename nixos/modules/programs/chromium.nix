{ config, pkgs, ... }:

# https://gist.github.com/SilentQQS/b23c28889cb957088ecf382400ad4325

let
  gpuFeatures = [
    "Vulkan"
    "VulkanFromANGLE"
    "DefaultANGLEVulkan"
    "AcceleratedVideoEncoder"
    "AcceleratedVideoDecoder"
  ];
  privacyFeatures = [
    #"ReducedSystemInfo"
    #"SpoofWebGLInfo"
    "NoCrossOriginReferrers"
    "MinimalReferrers"
  ];
  visualFeatures = [
    #"WaylandWindowDecorations"
    "TouchpadOverscrollHistoryNavigation"
  ];
  # Combine all features into one comma-separated string
  allFeatures = builtins.concatStringsSep "," (gpuFeatures ++ privacyFeatures ++ visualFeatures);

  chromiumFlags = [
    "--ozone-platform=wayland"
    "--ozone-platform-hint=wayland"
    "--enable-wayland-ime"
    # GPU support
    #"--use-gl=angle"
    #"--use-angle=gles"
    #"--use-angle=vulkan"
    "--vulkan-implementation=native"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workarounds"
    "--enable-zero-copy"
    "--enable-gpu-rasterization"

    # Combined features flag
    "--enable-features=${allFeatures}"

    # Fingerprinting Protections (Direct Flags)
    "--fingerprinting-canvas-image-data-noise"
    "--fingerprinting-canvas-measuretext-noise"
    "--fingerprinting-client-rects-noise"

    ## Extension Workaround
    #"--extension-mime-request-handling=always-prompt-for-install"
    #"--disable-features=IsolateOrigins,site-per-process"

    # User Agent
    #"--user-agent=\"Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15\""
  ];

# 1. Declaratively fetch the CRX file via Nix
  # This replaces the 'curl' command
  #cws-extension = pkgs.fetchurl {
  #  url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.5.3/Chromium.Web.Store.crx";
  #  # To get this hash, run: nix-prefetch-url [url]
  #  sha256 = "sha256:326443baec3d204b1358eba6aa025cf6bd930c08a0b98f6784e7a3236528445b";
  #};
  #username = "cytopia";

  ## 3. Define the JSON content
  #extensionJson = builtins.toJSON {
  #  external_crx = "${cws-extension}";
  #  external_version = "1.5.5.3";
  #};
in
{
  nixpkgs.overlays = [
    (self: super: {
      chromium = pkgs.ungoogled-chromium;
      ungoogled-chromium = super.ungoogled-chromium.override {
        commandLineArgs = chromiumFlags;
      };
    })
  ];
  #system.activationScripts.ungoogled-ext = {
  #  text = ''
  #    TARGET_DIR="/home/${username}/.config/chromium/External Extensions"
  #    mkdir -p "$TARGET_DIR"
  #    echo '${extensionJson}' > "$TARGET_DIR/pafkbggmedjldkkjmbifoocdbcaenjjg.json"
  #    chown -R ${username}:users "/home/${username}/.config/chromium"
  #  '';
  #};
  ##systemd.user.tmpfiles.rules = [
  #  "L+ /home/cytopia/.config/chromium/External\ Extensions/pafkbggmedjldkkjmbifoocdbcaenjjg.json - - - - ${pkgs.writeText "cws.json" (builtins.toJSON {
  #    external_crx = "${cws-extension}";
  #    external_version = "1.5.5.3";
  #  })}"
  #];
# 1. This places the JSON file on your actual filesystem
  # THIS IS THE MISSING PIECE:
    # We manually place the descriptor in the directory Chromium scans on startup.
  #environment.etc."chromium/extensions/pafkbggmedjldkkjmbifoocdbcaenjjg.json".text = builtins.toJSON {
  #  external_crx = "${chromium-web-store-crx}";
  #  external_version = "1.5.5.3";
  #};
  programs.chromium = {
    enable = true;

    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

    # Extensions currently do not work in ungoogled-chromium
    # https://github.com/NixOS/nixpkgs/pull/188086
    #extensions = [
    #  ## 1. THE UPDATER: Chromium Web Store (allows manual "Check for Updates")
    #  #"pafkbggmedjldkkjmbifoocdbcaenjjg;https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml"
	#  #"lpfndicmheibdoocpbebdihbehpkcgge;https://clients2.google.com/service/update2/crx"
    #  #"dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
    #  #"ddkjiahejlhfcafbddmgiahcphecmpfh" # ublock origin lite
    #  #"pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
    #  #"pflnpcinjbcfefgbejjfanemlgcfjbna" # tab numbers
    #];

    # This sets the JSON preference that toggles that specific checkbox
    initialPrefs = {
      "browser" = {
        "custom_chrome_frame" = false; # false = Use System Borders
      };
    };
    # This is where the magic happens:
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
        "de"
        "en-US"
      ];
      # 1. This tells the browser: "I know this extension is there, let it run."
      #"ExtensionInstallAllowlist" = [
      #  "pafkbggmedjldkkjmbifoocdbcaenjjg" # Chromium Web Store ID
	  #  "lpfndicmheibdoocpbebdihbehpkcgge"
      #];

      ## 2. This forces the UI to show it and keeps it from being "greyed out"
      #"ExtensionSettings" = {
      #  "pafkbggmedjldkkjmbifoocdbcaenjjg" = {
      #    "installation_mode" = "force_installed";
      #    "toolbar_pin" = "force_pinned";
      #    # DUMMY URL: We don't use it, but the policy validator requires it.
      #    "update_url" = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
      #  };
      #};

	  #"ExtensionInstallSources" = [ "https://*/*" "http://*/*" ];
      #"ExtensionInstallForcelist" = [
      #  "lpfndicmheibdoocpbebdihbehpkcgge;https://clients2.google.com/service/update2/crx"
      #];
      ### This allows you to install extensions from non-Google URLs (like GitHub)
      ###"ExtensionInstallSources" = [
      ###  "https://clients2.google.com/service/update2/crx/*"
      ###  "https://raw.githubusercontent.com/*"
      ###];
     ### We keep this ONLY for permissions, not for the download path.
      ##"ExtensionSettings" = {
      ##  "pafkbggmedjldkkjmbifoocdbcaenjjg" = {
      ##    "installation_mode" = "normal_installed";
      ##    "toolbar_pin" = "force_pinned";
	  ##    "update_url" = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
      ##  };
      ##};
    };
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];
}
