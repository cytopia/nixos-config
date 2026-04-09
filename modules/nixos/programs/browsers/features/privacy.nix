{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, name, ... }:
        let
          cfg = config.features.privacy;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy = {

            spoofLocale = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Normalizes date, time, number, and currency formatting to US English.
                Hides your specific regional OS settings from websites, blending your
                browser fingerprint into the largest generic pool of users.
              '';
            };

            disableReferrers = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Blocks the "Referer" header across different domains.
                Prevents destination websites from knowing which website you clicked the link from,
                stripping URL metadata leaks during navigation.
              '';
            };

            reduceFingerprinting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strips details from the User Agent string and Javascript APIs.
                Stops websites from seeing your exact CPU model or specific Linux distro version,
                making you look like a "Generic Linux User."
              '';
            };

            blockTrackingApis = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables the "Privacy Sandbox" (FLoC/Topics) to stop Chrome from locally
                profiling your interests for ads. Also blocks federated login prompts
                (like "Sign in with Google") to prevent identity tracking across domains.
              '';
            };

            blockThirdPartyCookies = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces a strict ban on all third-party tracking cookies.
                Prevents advertisers from following your session state across unrelated websites.
              '';
            };

            blockIntrusiveAds = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Strictly blocks ads on sites known to have intrusive or abusive ad practices,
                and disables media recommendations which can send viewing habits to backend servers.
              '';
            };

            disableTelemetry = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Kills "phone-home" traffic, crash reporting, background analytics, and component update checks.
                Disables HTML5 <a ping>, field trials (A/B testing), and diagnostic data collection
                (such as WebRTC logs or domain reliability reports) sent when pages fail to load.
              '';
            };

            disableCloudPredictions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables autofill predictions, payment method queries, and URL-keyed anonymized data collection.
                Prevents the browser from sending form field names or visited URLs to Google for
                "make searches and browsing better" features.
              '';
            };

            disableSyncAndAccount = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Explicitly disables browser sign-in and stops background account token generation.
                Disables Google Sync for passwords, bookmarks, history, and settings to prevent
                your local data from being uploaded to a centralized server.
              '';
            };

            killGoogleApis = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Hard-blocks Google API services by injecting invalid API keys into the environment.
                Acts as a kill-switch. Even if telemetry policies fail, Chrome's requests to Google's backend
                will be rejected with an authentication error.
              '';
            };

            disableSafeBrowsing = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces no Safe Browsing protection and disables the local heuristic engine
                that scans page DOMs for phishing. Disables uploading files to Google for deep
                malware scanning and sending extended telemetry.
              '';
            };

            disablePasswordLeakChecks = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables sending password hashes to Google to check for breaches.
                Also disables password reuse warnings (which require telemetry to evaluate).
              '';
            };

            disableDownloadEvaluations = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Prioritizes privacy by ensuring Chrome does not evaluate files or query
                Google during downloads. Allows all downloads without restrictions.
              '';
            };

            disableSpellcheck = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables local and cloud-enhanced spellchecking entirely.
                Prevents the browser from sending typed text to Google's cloud-enhanced
                spellcheck service and stops background dictionary downloads.
              '';
            };

            disableTranslation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables the built-in Google Translate prompt, live caption translation,
                and the local Translation Javascript API. Stops page content from being
                sent to Google for processing.
              '';
            };

            disableAccessibilityServices = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables sending images to Google to generate accessibility descriptions (Image Labels).
              '';
            };

            forceBlankNewTabPage = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces about:blank on new tabs to prevent leaking recently visited pages
                or search history thumbnails to shoulder surfers or local background scripts.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.disableTelemetry [
                # Disables HTML5 <a ping> attributes globally across the browser.
                # Prevents silent background POST requests to trackers when you click a link.
                "--no-pings"
                # Stops Chrome from sending diagnostic data to Google.
                # Prevents phoning home when a page fails to load or has SSL errors.
                "--disable-domain-reliability"
              ])

              (lib.optionals cfg.disableSafeBrowsing [
                # Disables the local heuristic engine that scans page DOMs for phishing.
                # Prevents the browser from sending suspicious page metadata to Google for verification.
                "--disable-client-side-phishing-detection"
              ])
            ];

            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.spoofLocale {
                # Overrides the OS locale specifically for the browser process.
                # Enforces standard US English to mask regional identity.
                "LC_ALL" = "en_US.UTF-8";
              })

              (lib.mkIf cfg.killGoogleApis {
                # Injects invalid credentials to act as a hard kill-switch for Google APIs.
                # Forces backend services to reject Chrome's requests entirely.
                "GOOGLE_API_KEY" = "no";
                "GOOGLE_DEFAULT_CLIENT_ID" = "no";
                "GOOGLE_DEFAULT_CLIENT_SECRET" = "no";
              })
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.disableReferrers [
                # Strips the HTTP Referer header entirely for cross-origin requests.
                # Ensures cross-site navigation does not leak the source URL.
                "NoCrossOriginReferrers"
                "MinimalReferrers"
              ])
              (lib.optionals cfg.reduceFingerprinting [
                # Truncates the User-Agent string and reduces entropy in JS hardware APIs.
                # Prevents tracking scripts from identifying your unique OS/CPU combination.
                "ReducedSystemInfo"
              ])
            ];

            internal.disableFeatures = lib.mkMerge [
              (lib.optionals cfg.blockTrackingApis [
                # Disables Google's localized ad-profiling engine (FLoC/Topics API).
                # Prevents the browser from silently categorizing your browsing habits.
                "PrivacySandboxAdsAPIs"
                # Blocks the Federated Credential Management API (FedCm).
                # Stops intrusive third-party identity prompts from tracking activity.
                "FedCm"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.blockTrackingApis {
                # Disables the consent prompt for the Privacy Sandbox.
                # Effectively opts the browser out of all built-in ad tracking generation.
                "PrivacySandboxPromptEnabled" = 2;
              })

              (lib.mkIf cfg.blockThirdPartyCookies {
                # Instructs the browser to strictly reject non-first-party cookies.
                # Severs the most common method of cross-site user tracking.
                "BlockThirdPartyCookies" = true;
              })

              (lib.mkIf (cfg.blockThirdPartyCookies && name == "brave") {
                # Forces Brave Shields to aggressively block trackers on all sites.
                # This policy only works on Brave; it is ignored by Google Chrome.
                "BraveShieldsEnabled" = true;
                "TrackersAndAdsBlocking" = "aggressive";
              })

              (lib.mkIf cfg.blockIntrusiveAds {
                # Enforces native blocking of abusive ad networks based on the Better Ads Standard.
                # A value of 2 enforces a strict block on offending domains.
                "AdsSettingForIntrusiveAdsSites" = 2;
                # Disables media consumption recommendations.
                # Prevents the browser from phoning home with video/audio interaction metrics.
                "MediaRecommendationsEnabled" = false;
              })

              (lib.mkIf cfg.disableTelemetry {
                # Core policy to disable crash reporting and usage statistics sent to Google.
                "MetricsReportingEnabled" = false;
                "UserFeedbackAllowed" = false;
                # A value of 2 disables field trials (A/B testing) pushed from the server.
                "ChromeVariations" = 2;
                # Disables reporting of domain reliability metrics and user satisfaction surveys.
                "DomainReliabilityAllowed" = false;
                "FeedbackSurveysEnabled" = false;
                "WebRtcEventLogCollectionAllowed" = false;
                "WebRtcTextLogCollectionAllowed" = false;
                # Stops Chrome from quietly downloading component updates in the background.
                "ComponentUpdatesEnabled" = false;
              })

              (lib.mkIf cfg.disableCloudPredictions {
                # A value of 2 disables autofill predictions entirely.
                # Prevents the browser from sending local form field names to Google's backend.
                "AutofillPredictionSettings" = 2;
                # Disables sending visited URLs to Google for the "Make searches and browsing better" feature.
                "UrlKeyedAnonymizedDataCollectionEnabled" = false;
                "PaymentMethodQueryEnabled" = false;
              })

              (lib.mkIf cfg.disableSyncAndAccount {
                # A value of 0 explicitly disables browser sign-in and background token generation.
                "BrowserSignin" = 0;
                "SyncDisabled" = true;
                "BrowserAddPersonEnabled" = false;
                "BrowserGuestModeEnabled" = false;
              })

              (lib.mkIf cfg.disableSafeBrowsing {
                # Enforces no Safe Browsing protection, relying on your DNS/network blocks instead.
                "SafeBrowsingProtectionLevel" = 0;
                # Disables uploading files for deep malware scanning and sending file metadata.
                "SafeBrowsingDeepScanningEnabled" = false;
                "SafeBrowsingExtendedReportingEnabled" = false;
                "SafeBrowsingProxiedRealTimeChecksAllowed" = false;
                # Disables integration with Advanced Protection and related surveys.
                "AdvancedProtectionAllowed" = false;
                "SafeBrowsingSurveysEnabled" = false;
              })

              (lib.mkIf cfg.disablePasswordLeakChecks {
                # Disables sending password hashes to Google to check for breaches.
                "PasswordLeakDetectionEnabled" = false;
                "PasswordProtectionWarningTrigger" = 0;
              })

              (lib.mkIf cfg.disableDownloadEvaluations {
                # A value of 0 ensures Chrome does not evaluate files or query Google during file downloads.
                "DownloadRestrictions" = 0;
              })

              (lib.mkIf cfg.disableSpellcheck {
                # Disables the cloud-enhanced spellcheck (sending typing to Google).
                "SpellCheckServiceEnabled" = false;
                # Disables the engine and clears the language list to stop dictionary downloads.
                "SpellcheckEnabled" = false;
                "SpellcheckLanguage" = [ ];
              })

              (lib.mkIf cfg.disableTranslation {
                # Disables built-in Translate prompts and live caption translation.
                "TranslateEnabled" = false;
                "LiveTranslateEnabled" = false;
                # Strictly blocks the Javascript API that allows sites to request local/cloud translation.
                "TranslatorAPIAllowed" = false;
              })

              (lib.mkIf cfg.disableAccessibilityServices {
                # Stops the browser from sending local images to Google for AI labeling.
                "AccessibilityImageLabelsEnabled" = false;
              })

              (lib.mkIf cfg.forceBlankNewTabPage {
                # Enforces about:blank on new tabs to prevent leaking recently visited pages.
                "NewTabPageLocation" = "about:blank";
              })
            ];

            internal.initialPreferences = lib.mkMerge [
              # Blocks intrusive "Sign in with Google/Facebook" slide-down prompts on all websites (*,*).
              # These prompts are a privacy risk because they allow identity providers to track
              # your browsing habits across different, unrelated third-party domains.
              # Injecting 'setting = 2' (Block) into the initial preferences guarantees this
              # tracking API is dead on arrival the very first time you open the browser.
              (lib.mkIf cfg.blockTrackingApis {
                "profile" = {
                  "content_settings" = {
                    "exceptions" = {
                      "federated-identity-api" = {
                        "*,*" = { "setting" = 2; };
                      };
                    };
                  };
                };
              })
            ];
          };
        }
      )
    );
  };
}
