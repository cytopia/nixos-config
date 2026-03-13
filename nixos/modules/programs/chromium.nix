{ config, pkgs, ... }:

# https://gist.github.com/SilentQQS/b23c28889cb957088ecf382400ad4325

let
  # GPU Optimizations
  gpuFeatures = [
    "Vulkan"
    "VulkanFromANGLE"
    "DefaultANGLEVulkan"
    "AcceleratedVideoEncoder"
    "AcceleratedVideoDecoder"
  ];
  gpuFlags = [
    # GPU support
    #"--use-gl=angle"
    #"--use-angle=gles"
    #"--use-angle=vulkan"
    "--vulkan-implementation=native"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workarounds"
    "--enable-zero-copy"
    "--enable-gpu-rasterization"
  ];

  # Privacy Enhancements
  privacyFeatures = [
    #"ReducedSystemInfo"
    #"SpoofWebGLInfo"
    "NoCrossOriginReferrers"
    "MinimalReferrers"
  ];
  privacyFlags = [
    # Fingerprinting Protections (Direct Flags)
    "--fingerprinting-canvas-image-data-noise"
    "--fingerprinting-canvas-measuretext-noise"
    "--fingerprinting-client-rects-noise"
    #"--disable-features=IsolateOrigins,site-per-process"
  ];

  # Visual Enhancements
  visualFeatures = [
    #"WaylandWindowDecorations"
    "TouchpadOverscrollHistoryNavigation"
  ];

  # Combine all features into one comma-separated string
  allFeatures = builtins.concatStringsSep "," (gpuFeatures ++ privacyFeatures ++ visualFeatures);

  chromiumFlags = [
    # Wayland specific
    "--ozone-platform=wayland"
    "--ozone-platform-hint=wayland"
    "--enable-wayland-ime"

    # Combined features flag
    "--enable-features=${allFeatures}"

    # User Agent
    #"--user-agent=\"Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15\""
  ] ++ gpuFlags ++ privacyFlags;

in
{
  nixpkgs.overlays = [
    (self: super: {
      chromium = super.chromium.override {
        commandLineArgs = chromiumFlags;
      };
    })
  ];

  programs.chromium = {
    enable = true;

    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

    # This sets the JSON preference that toggles that specific checkbox
    # ~/.config/chromium/Default/Preferences
    initialPrefs = {
      "browser" = {
        "custom_chrome_frame" = false; # false = Use System Borders
      };
      "extensions" = {
        "theme" = {
          "id" = "";
          "system_theme" = 1;
        };
      };
    };

    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
        "de"
        "en-US"
      ];
      ExtensionSettings = {
        # uBlock Origin Lite
        "ddkjiahejlhfcafbddmgiahcphecmpfh" = {
          "toolbar_pin" = "default_pinned";
        };
        # Privacy Badger
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" = {
          "toolbar_pin" = "default_pinned";
        };
        # Vimium
        "dbepggeogbaibhgnhhndojpepiihcmeb" = {
          "toolbar_pin" = "default_unpinned";
        };
      };
    };

    # Default installed extensions
    extensions = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh"  # uBlock Origin Lite
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"  # Privacy Badger
      "dbepggeogbaibhgnhhndojpepiihcmeb"  # Vimium
    ];
  };

  environment.systemPackages = with pkgs; [
    chromium
  ];
}
