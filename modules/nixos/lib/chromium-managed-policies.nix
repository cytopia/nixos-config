# chromium-policies.nix
# A reusable library of hardened Chromium enterprise policies.
# https://chromeenterprise.google/policies/

let
  # ==========================================
  # 1. ACCOUNTS
  # ==========================================
  account = {
    # 0 (Disable) explicitly disables browser sign-in and stops background account token generation.
    "BrowserSignin" = 0;
    # true (Disable) disables Google Sync for passwords, bookmarks, history, and settings.
    "SyncDisabled" = true;
    # false (Disable) prevents the "Add Profile" picker screen from showing up.
    "BrowserAddPersonEnabled" = false;
    # false (Disable) prevents users from bypassing rules via Guest Mode.
    "BrowserGuestModeEnabled" = false;
  };

  # ==========================================
  # 2. PASSWORDS
  # ==========================================
  passwords = {
    # false (Disable) disables the built-in Chrome password manager.
    "PasswordManagerEnabled" = false;
    "PasswordManagerPasskeysEnabled" = false;
    "PasswordManagerBlocklist" = [ "*" ];
    # false (Disable) disables sending password hashes to Google to check for breaches.
    "PasswordLeakDetectionEnabled" = false;
    # 0 (Disable) disables password reuse warnings (which require telemetry).
    "PasswordProtectionWarningTrigger" = 0;
  };

  # ==========================================
  # 3. AUTOFILL
  # ==========================================
  autofill = {
    # 2 (Disable) disables autofill predictions (prevents sending form field names to Google).
    "AutofillPredictionSettings" = 2;
    # false (Disable) disables saving and autofilling addresses.
    "AutofillAddressEnabled" = false;
    # false (Disable) disables saving and autofilling credit cards.
    "AutofillCreditCardEnabled" = false;
    # false (Disable) disables querying for saved payment methods via Google Pay.
    "PaymentMethodQueryEnabled" = false;
  };

  # ==========================================
  # 4. DOWNLOADS
  # ==========================================
  downloadRestrictions = {
    # 0 (Allow) prioritizes privacy; ensures Chrome does not evaluate files or query Google.
    "DownloadRestrictions" = 0;
  };

  # ==========================================
  # 5. SAFEBROWSING
  # ==========================================
  safeBrowsing = {
    # 0 (Disable) enforces no Safe Browsing protection.
    "SafeBrowsingProtectionLevel" = 0;
    # false (Disable) disables Google's Advanced Protection Program integration (heavy telemetry).
    "AdvancedProtectionAllowed" = false;
    # false (Disable) disables real-time Safe Browsing checks via proxy.
    "SafeBrowsingProxiedRealTimeChecksAllowed" = false;
    # false (Disable) disables surveys triggered by Safe Browsing security events.
    "SafeBrowsingSurveysEnabled" = false;
    # false (Disable) disables sending extra telemetry and file metadata to Google for Safe Browsing.
    "SafeBrowsingExtendedReportingEnabled" = false;
    # false (Disable) disables uploading files to Google for deep malware scanning.
    "SafeBrowsingDeepScanningEnabled" = false;
  };

  # ==========================================
  # 6. SPELLCHECK
  # ==========================================
  spellcheck = {
    # false (Disable) disables local spellchecking entirely.
    "SpellcheckEnabled" = false;
    # [ ] (Disable) ensures no spellcheck dictionaries are downloaded or loaded.
    "SpellcheckLanguage" = [ ];
  };

  # ==========================================
  # 7. USERINTERFACE
  # ==========================================
  googleUi = {
    # false (Disable) disables the Google Search side panel.
    "GoogleSearchSidePanelEnabled" = false;
    # false (Disable) disables promotional UI elements in Chrome.
    "PromotionsEnabled" = false;
  };

  # ==========================================
  # 8. TELEMETRY
  # ==========================================
  telemetry = {
    # false (Disable) core policy to disable crash reporting and usage statistics sent to Google.
    "MetricsReportingEnabled" = false;
    # false (Disable) disables the "Help Improve Chrome" feedback loop and bug reporting.
    "UserFeedbackAllowed" = false;
    # 2 (Disable) disables field trials (A/B testing) which alter browser behavior and send telemetry.
    "ChromeVariations" = 2;
    # false (Disable) disables sending URLs to Google for the "Make searches and browsing better" feature.
    "UrlKeyedAnonymizedDataCollectionEnabled" = false;
    # false (Disable) disables reporting of domain reliability metrics to Google.
    "DomainReliabilityAllowed" = false;
    # false (Disable) prevents Chrome from prompting users with satisfaction surveys.
    "FeedbackSurveysEnabled" = false;
  };

  # ==========================================
  # 9. CLOUDREPORTING
  # ==========================================
  cloudReporting = {
    # Because this is a standalone NixOS Linux machine and not a
    # Google Workspace MDM-enrolled device, these policies are dead weight:
    #
    ## false (Disable) prevents users from requesting extensions via cloud management approval flows.
    #"CloudExtensionRequestEnabled" = false;
    ## false (Disable) disables reporting of profile information to Google Cloud Management.
    #"CloudProfileReportingEnabled" = false;
    ## false (Disable) completely disables Chrome's enterprise cloud reporting engine.
    #"CloudReportingEnabled" = false;
    ## false (Disable) disables authenticated RPC reporting for user security events.
    #"UserSecurityAuthenticatedReporting" = false;
    ## false (Disable) disables sending user security telemetry signals to Google.
    #"UserSecuritySignalsReporting" = false;
  };

  # ==========================================
  # 10. DIAGNOSTICS
  # ==========================================
  diagnostics = {
    # false (Disable) disables collection of WebRTC event logs (audio/video diagnostic telemetry).
    "WebRtcEventLogCollectionAllowed" = false;
    # false (Disable) disables collection of WebRTC text logs for diagnostics.
    "WebRtcTextLogCollectionAllowed" = false;
  };

  # ==========================================
  # 11. TRACKING
  # ==========================================
  tracking = {
    # true (Block) enforces a strict ban on all third-party tracking cookies.
    "BlockThirdPartyCookies" = true;
    # 2 (Block) strictly blocks ads on sites known to have intrusive or abusive ad practices.
    "AdsSettingForIntrusiveAdsSites" = 2;
    # 2 (Disable) disables the Privacy Sandbox consent prompt, effectively opting out of all browser-based ad tracking and topic generation.
    "PrivacySandboxPromptEnabled" = 2;
    # false (Disable) disables media recommendations, which can send viewing habits to Google.
    "MediaRecommendationsEnabled" = false;
  };

  # ==========================================
  # 12. DNS
  # ==========================================
  dns = {
    # 2 (Disable) stops DNS prefetching and network prediction, preventing accidental data leaks.
    "NetworkPredictionOptions" = 2;
    # false (Disable) disables Chrome's built-in async DNS client, forcing it to respect the NixOS system DNS.
    "BuiltInDnsClientEnabled" = false;
    # false (Disable) disables checks that detect if DNS is being intercepted.
    "DNSInterceptionChecksEnabled" = false;
    # "off" (Disable) disables Chrome's internal DoH so it doesn't bypass system-level network filtering.
    "DnsOverHttpsMode" = "off";
    # false (Disable) disables querying for HTTPS DNS records (Type 65) over standard DNS.
    "AdditionalDnsQueryTypesEnabled" = false;
  };

  # ==========================================
  # 13. INTRANET
  # ==========================================
  intranet = {
    # false (Disable) disables Chromecast/Media Router discovery protocols (mDNS/SSDP) on your local network.
    "EnableMediaRouter" = false;
    # 1 (Disable) disables DNS interception checks for intranet domains, reducing startup queries.
    "IntranetRedirectBehavior" = 1;
    # [ "*://*" ] (Block) blocks public websites from making requests to the local network space (intranet).
    "LocalNetworkAccessBlockedForUrls" = [ "*://*" ];
    # [ "*://*" ] (Block) blocks public websites from making requests to the loopback address (localhost/127.0.0.1).
    "LoopbackNetworkBlockedForUrls" = [ "*://*" ];
  };

  # ==========================================
  # 14. HARDWAREPERMISSIONS
  # ==========================================
  hardwarePermissions = {
    # 3 (Ask) requires permission before tracking physical location.
    "DefaultGeolocationSetting" = 3;
    # 3 (Ask) requires permission before accessing Bluetooth devices.
    "DefaultWebBluetoothGuardSetting" = 3;
    # 3 (Ask) requires permission before accessing HID devices.
    "DefaultWebHidGuardSetting" = 3;
    # 3 (Ask) requires permission before accessing USB devices.
    "DefaultWebUsbGuardSetting" = 3;
    # 3 (Ask) requires permission before accessing Serial devices.
    "DefaultSerialGuardSetting" = 3;
    # 2 (Deny) blocks access to device sensors. (NOTE: Sensors do not support an "Ask" policy).
    "DefaultSensorsSetting" = 2;
  };

  # ==========================================
  # 15. OSPERMISSIONS
  # ==========================================
  osPermissions = {
    # 3 (Ask) requires permission before sites can manage windows/screens.
    "DefaultWindowManagementSetting" = 3;
    # 3 (Ask) requires permission before sites can enumerate local fonts (anti-fingerprinting).
    "DefaultLocalFontsSetting" = 3;
    # 3 (Ask) requires permission before a site can read from the clipboard.
    "DefaultClipboardSetting" = 3;
    # 2 (Block) blocks sites from detecting when you are away from your machine.
    "DefaultIdleDetectionSetting" = 2;
    # 3 (Ask) requires permission for File System API read access.
    "DefaultFileSystemReadGuardSetting" = 3;
    # 3 (Ask) requires permission for File System API write access.
    "DefaultFileSystemWriteGuardSetting" = 3;
    # false (Disable) strictly prevents Chrome from running background processes/apps after the last window is closed.
    "BackgroundModeEnabled" = false;
  };

  # ==========================================
  # 16. CONTENTPERMISSIONS
  # ==========================================
  contentPermissions = {
    # 3 (Ask) prompts before allowing web notifications.
    "DefaultNotificationsSetting" = 3;
    # 2 (Deny) strictly blocks popups. (NOTE: Popups do not support an "Ask" policy).
    "DefaultPopupsSetting" = 2;
  };

  # ==========================================
  # 17. NETWORKPERMISSIONS
  # ==========================================
  networkPermissions = {
    # 2 (Block) blocks sites from opening raw TCP/UDP sockets (Direct Sockets API).
    "DefaultDirectSocketsSetting" = 2;
    # "disable_non_proxied_udp" (Block) prevents WebRTC from leaking local/LAN IP addresses to websites.
    "WebRtcIPHandling" = "disable_non_proxied_udp";
    # true (Enable) encrypts the SNI domain name during TLS handshakes so ISPs cannot see your destination.
    "EncryptedClientHelloEnabled" = true;
  };

  # ==========================================
  # 18. CLOUDASSIST
  # ==========================================
  cloudAssist = {
    # false (Disable) disables sending images to Google for accessibility descriptions.
    "AccessibilityImageLabelsEnabled" = false;
    # false (Disable) disables local real-time caption translation.
    "LiveTranslateEnabled" = false;
    # false (Disable) disables the built-in Google Translate prompt (stops sending page text).
    "TranslateEnabled" = false;
    # false (Disable) disables the cloud-enhanced spellcheck service (stops sending typed text to Google).
    "SpellCheckServiceEnabled" = false;
  };

  # ==========================================
  # 19. CLOUDAI
  # ==========================================
  cloudAi = {
    # 1 (Disable) prevents Chrome from sharing multi-tab context with Google Drive/GenAI.
    "SearchContentSharingSettings" = 1;
    # 1 (Disable) turns off the new "AI Mode" integrations in the Omnibox and New Tab page.
    "AIModeSettings" = 1;
    # 1 (Block) strictly blocks the background Gemini app integrations within the browser UI.
    "GeminiSettings" = 1;
    # 2 (Disable) turns off the AI-powered history search feature (stops local index scanning).
    "HistorySearchSettings" = 2;
    # 2 (Disable) turns off the AI Tab Compare feature.
    "TabCompareSettings" = 2;
    # 2 (Disable) turns off the "Help me write" AI text generation assistant.
    "HelpMeWriteSettings" = 2;
    # 2 (Disable) turns off the ability to create custom themes and wallpapers via generative AI.
    "CreateThemesSettings" = 2;
    # 2 (Disable) turns off generative AI debugging explanations in Chrome Developer Tools.
    "DevToolsGenAiSettings" = 2;
  };

  # ==========================================
  # 20. LOCALAI
  # ==========================================
  localAi = {
    # 1 (Block) explicitly stops Chrome from silently downloading local foundational AI models to disk.
    "GenAILocalFoundationalModelSettings" = 1;
    # 1 (Block) prevents Gemini from acting on active web pages and reading DOM content.
    "GeminiActOnWebSettings" = 1;
    # false (Disable) disables built-in local AI APIs (LanguageModel, Summarization, Rewriter).
    "BuiltInAIAPIsEnabled" = false;
    # false (Disable) disables the built-in Translator API.
    "TranslatorAPIAllowed" = false;
  };

  # ==========================================
  # 21. UPDATES
  # ==========================================
  updates = {
    # ADD: false (Disable) stops Chrome from quietly downloading component updates in the background.
    # This prevents the "Safety Check" from phoning home to verify component versions.
    "ComponentUpdatesEnabled" = false;
  };

  # ==========================================
  # 22. Autoplay
  # ==========================================
  autoplay = {
    # false (Disable) blocks HTML5 media from auto-playing globally.
    "AutoplayAllowed" = false;
    # ADD: Explicitly whitelist YouTube so playlists and auto-advance still function.
    "AutoplayAllowlist" = [ "[*.]youtube.com" ];
  };

  # ==========================================
  # 23. CORE SECURITY & ISOLATION
  # ==========================================
  coreSecurity = {
    # true (Enable) forces strict OS-level process isolation for all cross-origin iframes (Mitigates Spectre).
    # This has performance downsides:
    #  *  The RAM Tax (10% to 20% Increase)
    #  *  CPU and IPC Overhead
    "SitePerProcess" = true;
    # false (Disable) turns off experimental Chrome features that lack full security audits.
    "BrowserLabsEnabled" = false;
    # 2 (Block) Strictly blocks mixed insecure (HTTP) content on secure pages.
    "DefaultInsecureContentSetting" = 2;

    # flase (Disable) Do not allow to install web-apps by the user
    "WebAppInstallByUserEnabled" = false;
  };

in
{
  # Exposed library properties completely free of conjunctions
  disableAccount = account;
  disablePasswords = passwords;
  disableAutofill = autofill;

  disableDownloadRestrictions = downloadRestrictions;
  disableSafeBrowsing = safeBrowsing;
  disableSpellcheck = spellcheck;
  disableGoogleUi = googleUi;

  disableTelemetry = telemetry;
  disableCloudReporting = cloudReporting;
  disableDiagnostics = diagnostics;
  disableTracking = tracking;

  disableDns = dns;
  disableIntranet = intranet;

  disableHardwarePermissions = hardwarePermissions;
  disableOsPermissions = osPermissions;
  disableContentPermissions = contentPermissions;
  disableNetworkPermissions = networkPermissions;

  disableCloudAssist = cloudAssist;
  disableCloudAi = cloudAi;
  disableLocalAi = localAi;

  disableUpdates = updates;
  disableAutoplay = autoplay;
  enableCoreSecurity = coreSecurity;
}
