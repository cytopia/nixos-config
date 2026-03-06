{ config, pkgs, ... }:

# https://gist.github.com/SilentQQS/b23c28889cb957088ecf382400ad4325

let
  gpuFeatures = [
    "Vulkan"
    "VulkanFromANGLE"
    "DefaultANGLEVulkan"
    "AcceleratedVideoEncoder"
  ];
  privacyFeatures = [
    "ReducedSystemInfo"
    "SpoofWebGLInfo"
    "NoCrossOriginReferrers"
    "MinimalReferrers"
  ];
  visualFeatures = [
    "WaylandWindowDecorations"
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

    # Extension Workaround
    "--extension-mime-request-handling=always-prompt-for-install"

    # User Agent
    "--user-agent=\"Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15\""
  ];
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

  programs.chromium = {
    enable = true;

    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

    # Extensions currently do not work in ungoogled-chromium
    # https://github.com/NixOS/nixpkgs/pull/188086
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # ublock origin lite
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
      "pflnpcinjbcfefgbejjfanemlgcfjbna" # tab numbers
    ];

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
    };
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];
}
