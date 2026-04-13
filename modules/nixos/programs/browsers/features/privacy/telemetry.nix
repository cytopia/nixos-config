{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.privacy.telemetry;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy.telemetry = {

            disableUsageAndCrashReports = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Kills "phone-home" traffic, crash reporting, and background analytics.
                Disables diagnostic data collection (such as WebRTC logs or domain reliability reports)
                sent when pages fail to load.
              '';
            };

            disableComponentUpdates = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Stops Chrome from quietly downloading component updates in the background.
                Note: This can break DRM (Widevine) and Certificate Revocation lists.
              '';
            };

            disableUrlKeyedAnonymizedData = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables sending visited URLs to Google for URL-keyed anonymized data collection.
              '';
            };

            disableHyperlinkPings = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables HTML5 <a ping> attributes globally across the browser.
                Prevents silent background POST requests to trackers when you click a link.
              '';
            };

            disableAbTesting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables field trials (A/B testing) pushed from the server.
              '';
            };

            disableEnterpriseReporting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables Chrome Enterprise machine and user reporting.
                Stops the browser from uploading system metadata, machine IDs, installed extension lists,
                URL-keyed metrics, and unmanaged device signals to Google.
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.disableHyperlinkPings [
                # Disables HTML5 <a ping> attributes globally across the browser.
                # Prevents silent background POST requests to trackers when you click a link.
                "--no-pings"
              ])
              (lib.optionals cfg.disableUsageAndCrashReports [
                # Stops Chrome from sending diagnostic data to Google.
                # Prevents phoning home when a page fails to load or has SSL errors.
                "--disable-domain-reliability"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableUsageAndCrashReports {
                # Core policy to disable crash reporting and usage statistics sent to Google.
                "MetricsReportingEnabled" = false;
                "UserFeedbackAllowed" = false;
                # Disables reporting of domain reliability metrics and user satisfaction surveys.
                "DomainReliabilityAllowed" = false;
                "FeedbackSurveysEnabled" = false;
                "WebRtcEventLogCollectionAllowed" = false;
                "WebRtcTextLogCollectionAllowed" = false;
              })

              (lib.mkIf cfg.disableComponentUpdates {
                # Stops Chrome from quietly downloading component updates in the background.
                "ComponentUpdatesEnabled" = false;
              })

              (lib.mkIf cfg.disableUrlKeyedAnonymizedData {
                # Disables sending visited URLs to Google for the "Make searches and browsing better" feature.
                "UrlKeyedAnonymizedDataCollectionEnabled" = false;
              })

              (lib.mkIf cfg.disableAbTesting {
                # Disables field trials (A/B testing) pushed from the server.
                "ChromeVariations" = 1;
              })

              (lib.mkIf cfg.disableEnterpriseReporting {
                # Blocks the browser from uploading system metadata, IDs, and installed extension lists.
                "ReportExtensionsAndPluginsData" = false;
                "ReportMachineIDData" = false;
                "ReportPolicyData" = false;
                "ReportUserIDData" = false;
                "ReportVersionData" = false;
                # Kills consent flow prompts for collecting unmanaged device signals.
                "UnmanagedDeviceSignalsConsentFlowEnabled" = false;
                # Blocks URL-keyed telemetry metrics uploads.
                "UrlKeyedMetricsAllowed" = false;
              })

            ];
          };
        }
      )
    );
  };
}
