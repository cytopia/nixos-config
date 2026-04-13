{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.privacy.remoteServices;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy.remoteServices = {

            disableCloudPredictions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables autofill predictions, payment method queries, and URL-keyed anonymized data collection.
                Prevents the browser from sending form field names or visited URLs to Google for
                "make searches and browsing better" features.
              '';
            };

            disableSafeBrowsing = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces no Safe Browsing protection and disables the local heuristic engine
                that scans page DOMs for phishing. Disables uploading files to Google for deep
                malware scanning and sending extended telemetry. Prioritizes privacy by ensuring
                Chrome does not evaluate files or query Google during downloads.
              '';
            };

            disableCloudSpellcheck = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables local and cloud-enhanced spellchecking entirely.
                Prevents the browser from sending typed text to Google's cloud-enhanced
                spellcheck service and stops background dictionary downloads.
              '';
            };

            disableLiveTranslation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables the built-in Google Translate prompt, live caption translation,
                and the local Translation Javascript API. Stops page content from being
                sent to Google for processing.
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

            disableImageAccessibility = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables sending images to Google to generate accessibility descriptions (Image Labels).
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.flags = lib.mkMerge [
              (lib.optionals cfg.disableSafeBrowsing [
                # Disables the local heuristic engine that scans page DOMs for phishing.
                # Prevents the browser from sending suspicious page metadata to Google for verification.
                "--disable-client-side-phishing-detection"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableCloudPredictions {
                # A value of 2 disables autofill predictions entirely.
                # Prevents the browser from sending local form field names to Google's backend.
                "AutofillPredictionSettings" = 2;
                # Disables sending visited URLs to Google for the "Make searches and browsing better" feature.
                "UrlKeyedAnonymizedDataCollectionEnabled" = false;
                "PaymentMethodQueryEnabled" = false;
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
                # A value of 0 ensures Chrome does not evaluate files or query Google during file downloads.
                "DownloadRestrictions" = 0;
              })

              (lib.mkIf cfg.disablePasswordLeakChecks {
                # Disables sending password hashes to Google to check for breaches.
                "PasswordLeakDetectionEnabled" = false;
                "PasswordProtectionWarningTrigger" = 0;
              })

              (lib.mkIf cfg.disableCloudSpellcheck {
                # Disables the cloud-enhanced spellcheck (sending typing to Google).
                "SpellCheckServiceEnabled" = false;
                # Disables the engine and clears the language list to stop dictionary downloads.
                "SpellcheckEnabled" = false;
                "SpellcheckLanguage" = [ ];
              })

              (lib.mkIf cfg.disableLiveTranslation {
                # Disables built-in Translate prompts and live caption translation.
                "TranslateEnabled" = false;
                "LiveTranslateEnabled" = false;
                # Strictly blocks the Javascript API that allows sites to request local/cloud translation.
                "TranslatorAPIAllowed" = false;
              })

              (lib.mkIf cfg.disableImageAccessibility {
                # Stops the browser from sending local images to Google for AI labeling.
                "AccessibilityImageLabelsEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
