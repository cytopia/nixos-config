{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, name, ... }:
        let
          cfg = config.features.privacy.webTracking;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.privacy.webTracking = {

            spoofLocale = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Normalizes date, time, number, and currency formatting to US English.
                Hides your specific regional OS settings from websites, blending your
                browser fingerprint into the largest generic pool of users.
              '';
            };

            stripReferrers = lib.mkOption {
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
                Also limits regional details leaked via the Accept-Language HTTP header.
              '';
            };

            blockPrivacySandbox = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables the "Privacy Sandbox" (FLoC/Topics) to stop Chrome from locally
                profiling your interests for ads.
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
                Strictly blocks ads on sites known to have intrusive or abusive ad practices.
              '';
            };

            disableMediaRouterTracking = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables media recommendations which can send viewing habits to backend servers.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.envVars = lib.mkMerge [
              (lib.mkIf cfg.spoofLocale {
                # Overrides the OS locale specifically for the browser process.
                # Enforces standard US English to mask regional identity.
                "LC_ALL" = "en_US.UTF-8";
              })
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.stripReferrers [
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
              (lib.optionals cfg.blockPrivacySandbox [
                # Disables Google's localized ad-profiling engine (FLoC/Topics API).
                # Prevents the browser from silently categorizing your browsing habits.
                "PrivacySandboxAdsAPIs"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.blockPrivacySandbox {
                # Disables the consent prompt for the Privacy Sandbox.
                # Effectively opts the browser out of all built-in ad tracking generation.
                "PrivacySandboxPromptEnabled" = false;
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
              })

              (lib.mkIf cfg.disableMediaRouterTracking {
                # Disables media consumption recommendations.
                # Prevents the browser from phoning home with video/audio interaction metrics.
                "MediaRecommendationsEnabled" = false;
              })

              (lib.mkIf cfg.reduceFingerprinting {
                # Reduces the amount of language and regional data sent in the Accept-Language header.
                "ReduceAcceptLanguageEnabled" = true;
              })
            ];
          };
        }
      )
    );
  };
}
