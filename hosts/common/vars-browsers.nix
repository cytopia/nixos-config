{
  appScaleFactor,
  dohServer,
  dohCertPath,
  ...
}:

let

  ###
  ### Security Settings
  ###
  security = {
    attackSurface = {
      disablePasswordManager = true;
      disableAutofill = true;
      disableBrowserLabs = true;
      disablePwaInstallation = true;
    };
    engineIsolation = {
      strictProcessIsolation = true;
      sandboxSystemServices = true;
    };
    sitePermissions = {
      strictGeolocation = true;
      strictHardwarePermissions = true;
      blockSensors = true;
      strictOsPermissions = true;
      blockIdleDetection = true;
      strictClipboardAccess = true;
      blockSilentPrinting = true;
      strictNotifications = true;
      blockPopups = true;
      preventCrossSiteAuth = true;
      blockDirectSockets = true;
      disableAutoplay = true;
      autoplayWhitelist = [ "[*.]youtube.com" ];
    };
    systemIntegration = {
      disableOsKeyring = true;
      disableRemoteAccess = true;
      strictExternalProtocols = true;
      blockExternalExtensions = true;
      disableBackgroundMode = true;
      enforceSecurityWarnings = true;
    };
    tls = {
      forceStrictTls = true;
      preventSslBypass = false;
    };
  };

  ###
  ### Privacy Settings
  ###
  privacy = {
    identity = {
      disableBrowserSync = true;
      blockFederatedLogins = true;
      disablePhoneHubIntegration = true;
      disableDeveloperProfileLinking = true;
      disableFamilyPasswordSharing = true;
      disableCloudShopping = true;
      hardKillApis = true;
    };
    localState = {
      forceBlankNewTabPage = true;
      limitDataRetention = false;
      disableLocalDataScraping = true;
    };
    remoteServices = {
      disableAutofillPredictions = true;
      disablePaymentMethodQueries = true;
      disableSafeBrowsing = true;
      disableDownloadEvaluations = true;
      disableCloudSpellcheck = true;
      disableLiveTranslation = true;
      disablePasswordLeakChecks = true;
      disableImageAccessibility = true;
    };
    telemetry = {
      disableUsageAndCrashReports = true;
      disableComponentUpdates = true;
      disableUrlKeyedAnonymizedData = true;
      disableHyperlinkPings = true;
      disableAbTesting = true;
      disableEnterpriseReporting = true;
    };
    webTracking = {
      spoofLocale = true;
      stripReferrers = true;
      reduceFingerprinting = true;
      blockPrivacySandbox = true;
      blockThirdPartyCookies = true;
      blockIntrusiveAds = true;
      disableMediaRouterTracking = true;
    };
  };

  ###
  ### AI Settings
  ###
  ai = {
    creativeUi = {
      disableGenAiThemes = true;
    };
    developer = {
      disableDevAi = true;
    };
    gemini = {
      disableGemini = true;
    };
    generativeProductivity = {
      disableMasterGenAiSwitch = true;
      disableContextSharing = true;
      disableAiMode = true;
      disableAiHistorySearch = true;
      disableTabCompare = true;
      disableHelpMeWrite = true;
    };
    onDevice = {
      disableLocalAiModels = true;
      disableHistoryClusters = true;
    };
  };

  ###
  ### Networking Settings
  ###
  networkingBlockWebRtc = {
    webrtc = {
      preventIpLeaks = true;
    };
    ntp = {
      disableNetworkTimeSync = true;
    };
    dns = {
      enableBuiltInDns = true;
      disableInterceptionChecks = true;
      disableIntranetRedirectChecks = true;
      enableEncryptedClientHello = true;
      enableAdditionalQueryTypes = true;
      doh = {
        enable = true;
        mode = "secure";
        template = dohServer;
      };
    };
    prefetching = {
      disableNetworkPrediction = true;
    };
    intranet = {
      blockPublicToPrivateRouting = true;
      disableMediaRouter = true;
    };
  };
  networkingAllowWebRtc = {
    webrtc = {
      preventIpLeaks = false;
    };
    ntp = {
      disableNetworkTimeSync = true;
    };
    dns = {
      enableBuiltInDns = true;
      disableInterceptionChecks = true;
      disableIntranetRedirectChecks = true;
      enableEncryptedClientHello = true;
      enableAdditionalQueryTypes = true;
      doh = {
        enable = true;
        mode = "secure";
        template = dohServer;
      };
    };
    prefetching = {
      disableNetworkPrediction = true;
    };
    intranet = {
      blockPublicToPrivateRouting = true;
      disableMediaRouter = true;
    };
  };

  ###
  ### Certificate Settings
  ###
  certificates = {
    customCaCerts = [
      {
        name = "dnscrypt-proxy";
        path = dohCertPath;
      }
    ];
  };

  ###
  ### Search Settings
  ###
  search = {
    provider = "duckduckgo";
    disableSearchSuggestions = true;
  };

  ###
  ### Scaling Settings
  ###
  scaling = {
    factor = appScaleFactor;
    waylandFractionalScaling = true;
  };

  ###
  ### Initial Preferences
  ###
  preferences = {
    restoreLastSession = true;
    showBookmarksBar = false;
    systemTheme = "system";
    cleanUi = true;
  };

  ###
  ### Hardware Settings (Vulkan)
  ###
  hardwareVulkan = {
    graphics = {
      backend = "vulkan";
      skiaGraphite = false;
      treesInViz = true;
      forceHardwareMesa = true;
      hideVulkanLoader = false;
      # Block OBS from injecting into the browser
      disabledVulkanLayers = [
        "VK_LAYER_OBS_vkcapture_32"
        "VK_LAYER_OBS_vkcapture_64"
      ];
    };
    video = {
      decodingBackend = "vaapi";
      blockSoftwareEncoders = true;
    };
  };
  hardwareGles = {
    graphics = {
      backend = "gles";
      skiaGraphite = false;
      treesInViz = true;
      forceHardwareMesa = true;
      hideVulkanLoader = true;
      # Block OBS from injecting into the browser
      disabledVulkanLayers = [
        "VK_LAYER_OBS_vkcapture_32"
        "VK_LAYER_OBS_vkcapture_64"
      ];
    };
  };

in
{
  settings = {
    scaling = scaling;
    preferences = preferences;
    search = search;

    security = security;
    privacy = privacy;
    ai = ai;

    networkingAllowWebRtc = networkingAllowWebRtc;
    networkingBlockWebRtc = networkingBlockWebRtc;
    certificates = certificates;

    hardwareVulkan = hardwareVulkan;
    hardwareGles = hardwareGles;
  };
}
