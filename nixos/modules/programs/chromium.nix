{ config, pkgs, ... }:

# https://gist.github.com/SilentQQS/b23c28889cb957088ecf382400ad4325




# TODO:
# Make sure chromium uses the system DNS by
# Disabling 'Secure DNS'
# and by disabling these flags
# Disable #use-dns-https-svcb-alpn.
# Disable #enable-async-dns (Chrome only).
# Disable #encrypted-client-hello (Chrome only).
#
# What about this???
# chrome.exe --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE 127.0.0.1"
#
# TODO: 2
# Disable: Preload Pages


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


  #
  # ALl available chromium flags
  # https://peter.sh/experiments/chromium-command-line-switches/
  #

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
      "dns_prefetching" = {
        "enabled" = false;
       };
    };

    # https://chromeenterprise.google/policies/
    # Examples: https://github.com/SenseiDeElite/chromium-policies.json
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;

	  "TranslatorAPIAllowed" = false;
	  "UserFeedbackAllowed" = false;

	  "BuiltInAIAPIsEnabled" = false;

	  "ChromeVariations" = 2;
	  "EnhancedNetworkVoicesInSelectToSpeakAllowed" = false;
	  "ListenToThisPageEnabled" = false;
	  "AccessibilityImageLabelsEnabled" = false;
	  "BrowserNetworkTimeQueriesEnabled" = false;
	  "CloudExtensionRequestEnabled" = false;
	  "CloudProfileReportingEnabled" = false;
	  "CloudReportingEnabled" = false;

	  "UserSecurityAuthenticatedReporting" = false;
	  "UserSecuritySignalsReporting" = false;

	  "GeminiActOnWebSettings" = 1;
	  "GenAILocalFoundationalModelSettings" = 1;
	  "GenAiDefaultSettings" = 2;

	  "GoogleSearchSidePanelEnabled" = false;
	  "LiveTranslateEnabled" = false;

      # Metrics send to google
      "MetricsReportingEnabled" = false;
      "DomainReliabilityAllowed" = false;
      "FeedbackSurveysEnabled" = false;
      "InsightsExtensionEnabled" = false;
      "UrlKeyedAnonymizedDataCollectionEnabled" = false;
      "DeviceMetricsReportingEnabled" = false;
      "PluginVmDataCollectionAllowed" = false;
	  "WebRtcEventLogCollectionAllowed" = false;
	  "WebRtcTextLogCollectionAllowed" = false;

	  "IntranetRedirectBehavior" = 1;
	  "MediaRecommendationsEnabled" = false;

      "DeviceActivityHeartbeatEnabled" = false;
      "ReportDeviceActivityTimes" = false;

      "AdsSettingForIntrusiveAdsSites" = 2; # Do not allow ads on sites with intrusive ads

      "AdvancedProtectionAllowed" = false;
      "DownloadRestrictions" = 0;

      "PromotionsEnabled" = false;
      "SearchSuggestEnabled" = false;

      "PasswordManagerEnabled" = false;
      "PasswordLeakDetectionEnabled" = false;
	  "PasswordProtectionWarningTrigger" = 0;

	  "SpellCheckServiceEnabled" = false;

      "SafeBrowsingEnabled" = false;
      "SafeBrowsingProtectionLevel" = 0;
      "SafeBrowsingProxiedRealTimeChecksAllowed" = false;
      "SafeBrowsingForTrustedSourcesEnabled" = false;
      "SafeBrowsingSurveysEnabled" = false;
      "SafeBrowsingExtendedReportingEnabled" = false;
      "SafeBrowsingDeepScanningEnabled" = false;

      "AutofillPredictionSettings" = 2;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "PaymentMethodQueryEnabled" = false;

      "AutomatedPasswordChangeSettings" = 2; # DENY
      "DefaultGeolocationSetting" = 2;

      "DefaultBrowserSettingEnabled" = false;

      "SpellcheckEnabled" = false;
      "SpellcheckLanguage" = [];
      # 5 = Open New Tab Page
      # 1 = Restore the last session
      # 4 = Open a list of URLs
      # 6 = Open a list of URLs and restore the last session
      "RestoreOnStartup" = 1;

      "DefaultWindowManagementSetting" = 3;  # ask
      "DefaultLocalFontsSetting" = 3; # ask
      "DefaultFileSystemReadGuardSetting" = 3; # ask
      "DefaultFileSystemWriteGuardSetting" = 3 ; # ask
      "DefaultNotificationsSetting" = 3; # ask
      "DefaultWebBluetoothGuardSetting" = 3; # ask
      "DefaultWebHidGuardSetting" = 3; # ask
      "DefaultWebUsbGuardSetting" = 3; # ask
      "DefaultPopupsSetting" = 2; # DENY
      "DefaultSensorsSetting" = 2; # DENY
      "DefaultSerialGuardSetting" = 3; # DENY

      # Disable Chromes own DNS
      "NetworkPredictionOptions" = 2;
      "BuiltInDnsClientEnabled" = false;
      "DNSInterceptionChecksEnabled" = false;
      "DnsOverHttpsMode" = "off";
      "DnsPrefetchingEnabled" = false;
      "AdditionalDnsQueryTypesEnabled" = false;
      "DnsOverHttpsExcludedDomains" = [ "*" ];
      "EnableMediaRouter" = false;  # chrome-cast discovery
      "TranslateEnabled" = false;

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
