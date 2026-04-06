{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.programs.thunderbird;

  # --- POLICIES ---

  dohPolicies = {
    # This policy adds the custom CA certificate path to Thunderbird's certificate store.
    # It allows the application to trust the local DoH server's certificate.
    # Essential for verifying the local DNSCrypt or DoH proxy connection securely.
    Certificates.Install = [ cfg.dnsOverHttps.caCertPath ];
  };

  appUpdatePolicies = {
    # Disables the built-in application updater completely.
    # In NixOS, updates are strictly managed declaratively via the package manager.
    # This prevents Thunderbird from mutating itself or polling Mozilla for updates.
    DisableAppUpdate = true;

    # Disables background extension updates at the policy level.
    # Complements the preference settings to ensure no supply chain attacks via extensions.
    # Requires all extensions to be updated manually or via NixOS package bumps.
    ExtensionUpdate = false;
  };

  telemetryPolicies = {
    # Completely disables all telemetry data collection and reporting.
    # This enforces a hard block at the enterprise policy level, preventing any local
    # or remote data gathering regarding application usage, performance, or errors.
    DisableTelemetry = true;

  };

  uiPolicies = {
    # Disables the prompt that offers to save passwords in the built-in password manager.
    # For highly secure environments, external, encrypted credential managers (like KeepassXC or pass) should be used.
    # This prevents sensitive credentials from being stored in the browser's local database.
    OfferToSaveLogins = false;

    # Disables the built-in password manager completely.
    # Prevents the application from accessing or auto-filling stored credentials.
    # Forces reliance on a more secure, system-wide secret management solution.
    PasswordManagerEnabled = false;
  };

  searchPolicies = {
    # Prevents the installation of new search engines by the user or websites.
    # Locks down the search configuration to only what is declaratively defined.
    # Protects against malicious scripts hijacking the default search provider.
    SearchEngines = {
      PreventInstalls = true;
    };
  };

  # --- PREFERENCES ---

  dohPreferences = {
    # Forces DNS-over-HTTPS (DoH) in strict mode.
    # Mode 3 means DoH is strictly required, and no fallback to standard DNS is permitted.
    # This completely eliminates plaintext DNS leaks.
    "network.trr.mode" = 3;

    # Specifies the URL for the DoH server to use.
    # In this configuration, it points to the locally hosted or specified DoH proxy.
    # This ensures no third-party DoH resolvers (like Cloudflare or Google) are used.
    "network.trr.uri" = cfg.dnsOverHttps.url;

    # Specifies the custom URL for the DoH server.
    # Must match network.trr.uri to ensure Thunderbird uses the correct endpoint.
    # Prevents any hardcoded defaults from taking precedence.
    "network.trr.custom_uri" = cfg.dnsOverHttps.url;

    # Disables falling back to plaintext DNS when the DoH server returns an empty response.
    # Standard behavior might attempt a regular DNS request if the DoH server fails to resolve.
    # Disabling this prevents DNS leaks when resolution fails.
    "network.trr.fallback-on-zero-response" = false;

    # Skips the wait for a confirmation of the TRR (Trusted Recursive Resolver) connection.
    # This prevents Thunderbird from checking a Mozilla server to confirm DoH is working.
    # It stops an unnecessary ping home to check network connectivity.
    "network.trr.wait-for-confirmation" = false;

    # Disables telemetry related to the TRR connection confirmation.
    # Ensures that success or failure of the DoH connection isn't reported to Mozilla.
    # Enhances privacy by keeping DNS server usage metadata local.
    "network.trr.confirmation_telemetry_enabled" = false;

    # Enables the use of HTTPS Resource Records (RR) as Alternative Services.
    # This allows Thunderbird to upgrade connections based on DNS records securely.
    # Improves performance and security using modern DNS features.
    "network.dns.use_https_rr_as_altsvc" = true;

    # Enables Encrypted Client Hello (ECH) configuration.
    # ECH encrypts the Server Name Indication (SNI), hiding the domains you connect to.
    # This is critical for preventing ISPs or network eavesdroppers from tracking mail servers.
    "network.dns.echconfig.enabled" = true;

    # Enables ECH configuration specifically over HTTP/3.
    # Ensures that even when using newer HTTP/3 transport, SNI remains encrypted.
    # Hardens the privacy against advanced network DPI (Deep Packet Inspection).
    "network.dns.http3_echconfig.enabled" = true;

    # Enforces using native HTTPS queries for DNS resolution.
    # Helps with fetching ECH and other HTTPS-specific DNS records directly.
    # Prevents fallback to insecure resolution methods.
    "network.dns.native_https_query" = true;

    # Disables falling back to the origin server when ECH fails.
    # If a server claims to support ECH but fails, this forces a connection failure instead of dropping encryption.
    # Completely prevents downgrade attacks that would leak the SNI in plaintext.
    "network.dns.echconfig.fallback_to_origin_when_all_failed" = false;
  };

  networkPreferences = {
    # Forces all DNS requests for SOCKS proxies to NOT be resolved remotely.
    # This ensures that every single DNS request ALWAYS hits the local DNS resolver.
    # Prevents the SOCKS proxy from resolving hostnames, maintaining control locally.
    "network.proxy.socks_remote_dns" = false;

    # Enforces local DNS resolution specifically for SOCKS5 proxies.
    # An explicit directive to prevent remote DNS queries when using SOCKS5.
    # Guarantees local DNS resolver is always consulted even inside a VPN.
    "network.proxy.socks5_remote_dns" = false;

    # Disables DNS prefetching, which resolves domains found in emails/webpages before you click them.
    # Prefetching causes unnecessary DNS lookups that leave a trail of what you might be viewing.
    # By disabling it, only explicit user actions trigger network activity.
    "network.dns.disablePrefetch" = true;

    # Disables DNS prefetching specifically for domains discovered over HTTPS connections.
    # Provides the same protection as disablePrefetch, but explicitly for encrypted channels.
    # Eliminates background DNS noise completely.
    "network.dns.disablePrefetchFromHTTPS" = true;

    # Disables prefetching of the next expected webpage or link.
    # Thunderbird uses the browser engine and might try to preload links.
    # This saves bandwidth and prevents contacting servers without explicit interaction.
    "network.prefetch-next" = false;

    # Disables the network predictor, which anticipates user navigation to speed up loading.
    # The predictor builds a history of your actions to guess the next server to connect to.
    # Turning it off prevents algorithmic network connections and local history profiling.
    "network.predictor.enabled" = false;

    # Explicitly disables prefetching initiated by the network predictor.
    # Acts as a secondary safeguard against any predictive connections.
    # Ensures absolute silence until the user clicks or opens something.
    "network.predictor.enable-prefetch" = false;

    # Disables speculative parallel connections, which open TCP connections in advance.
    # When you hover over a link, it might open a connection just in case.
    # This stops silent handshakes with external servers you haven't explicitly requested.
    "network.http.speculative-parallel-limit" = 0;

    # Disables the connectivity service that pings Mozilla/Firefox servers to check for internet access.
    # This stops the background pings to 'detectportal.firefox.com'.
    # Essential for a completely silent, offline-first posture.
    "network.connectivity-service.enabled" = false;

    # Disables captive portal detection.
    # Prevents Thunderbird from connecting to an external server to check for public Wi-Fi login pages.
    # Essential for avoiding random pings to HTTP endpoints on network changes.
    "network.captive-portal-service.enabled" = false;

    # Forces Thunderbird to show Punycode for Internationalized Domain Names (IDNs).
    # Protects against homograph attacks where malicious domains look visually identical to trusted ones.
    # A critical security measure to prevent phishing via deceptive URLs in emails.
    "network.IDN_show_punycode" = true;

    # Disables IPv6 network connections.
    # While IPv6 is modern, it can sometimes bypass VPNs, Tor, or proxies, leading to IP leaks.
    # Forcing IPv4-only ensures connections only go through predictable, routable paths.
    "network.dns.disableIPv6" = true;
  };

  telemetryPreferences = {
    # Disables the data submission policy entirely.
    # Acts as a master switch for the data reporting service (different from toolkit.telemetry).
    # Completely severs the data reporting pipeline.
    "datareporting.policy.dataSubmissionEnabled" = false;

    # Empties the URL used for mail instrumentation (telemetry specific to the mail UI).
    # Prevents the collection of data on how you interact with your inbox.
    # Eliminates another specialized telemetry endpoint.
    "mail.instrumentation.postUrl" = "";

    # Disables prompting the user to opt-in to mail instrumentation.
    # Removes the annoying popup asking for permission to collect data.
    # Ensures the user is never bothered with telemetry requests.
    "mail.instrumentation.askUser" = false;

    # Sets the user opt-in status for mail instrumentation to false.
    # Explicitly registers that the user has denied data collection.
    # Overrides any accidental or previous opt-ins.
    "mail.instrumentation.userOptedIn" = false;
  };

  privacyPreferences = {
    # Disables DNS prefetching for anchors within HTTP documents.
    # Stops Thunderbird from resolving domains linked in plain text emails.
    # Completely blocks background resolution of embedded links.
    "dom.prefetch_dns_for_anchor_http_document" = false;

    # Disables DNS prefetching for anchors within HTTPS documents.
    # Stops Thunderbird from resolving domains linked in secure emails.
    # Extends the anchor prefetch protection to all document contexts.
    "dom.prefetch_dns_for_anchor_https_document" = false;

    # Disables the Geolocation API entirely.
    # Prevents any script, addon, or feature from requesting the physical location of the device.
    # Removes the capability to leak physical coordinates via network or Wi-Fi scanning.
    "geo.enabled" = false;

    # Clears the URL used to look up geolocation data.
    # Even if geolocation were somehow bypassed, it would have nowhere to send the data.
    # Prevents phoning home to Google's or Mozilla's location services.
    "geo.provider.network.url" = "";

    # Disables the SafeBrowsing malware checking feature.
    # While it provides security, it works by sending hashes of URLs and files to Google/Mozilla.
    # This is a massive privacy risk as it leaks what links you receive in emails.
    "browser.safebrowsing.malware.enabled" = false;

    # Disables the SafeBrowsing phishing checking feature.
    # Similar to malware checking, this phones home to verify URLs against a blocklist.
    # Disabling it prevents third-party tracking of the links inside your mailbox.
    "browser.safebrowsing.phishing.enabled" = false;

    # Disables remote SafeBrowsing checks for downloaded files.
    # Prevents Thunderbird from sending file metadata or hashes to external servers when you save attachments.
    # Ensures that what you download remains strictly your business.
    "browser.safebrowsing.downloads.remote.enabled" = false;

    # Disables the SafeBrowsing feature entirely (master switch).
    # Provides a blanket ban on all SafeBrowsing mechanisms.
    # Necessary to eliminate all Google/Mozilla reputation tracking.
    "browser.safebrowsing.downloads.enabled" = false;

    # Empties the SafeBrowsing provider's update URL (Google legacy).
    # Removes the endpoint used to fetch new blocklists.
    # Hardcodes the inability to phone home to Google.
    "browser.safebrowsing.provider.google.updateURL" = "";

    # Empties the SafeBrowsing provider's gethash URL (Google legacy).
    # Removes the endpoint used to perform remote hash lookups.
    # Further neuters the Google SafeBrowsing integration.
    "browser.safebrowsing.provider.google.gethashURL" = "";

    # Empties the SafeBrowsing provider's update URL (Google v4 API).
    # Removes the endpoint for the newer version of Google's SafeBrowsing.
    # Covers more recent API integrations from phoning home.
    "browser.safebrowsing.provider.google4.updateURL" = "";

    # Empties the SafeBrowsing provider's gethash URL (Google v4 API).
    # Removes the endpoint for remote lookups on the newer API.
    # Eliminates another avenue for URL leaking.
    "browser.safebrowsing.provider.google4.gethashURL" = "";

    # Disables SafeBrowsing data sharing with Google (v4 API).
    # Prevents sharing extended telemetry or threat hits with Google.
    # Absolutely crucial for anonymity.
    "browser.safebrowsing.provider.google4.dataSharing.enabled" = false;

    # Disables the Google v5 SafeBrowsing provider entirely.
    # Shuts down the most recent iteration of Google's SafeBrowsing service.
    # Keeps the application isolated from all Google tracking systems.
    "browser.safebrowsing.provider.google5.enabled" = false;

    # Empties the SafeBrowsing provider's gethash URL (Mozilla).
    # Removes the endpoint used by Mozilla's own tracking protection lists.
    # Prevents phoning home to Mozilla for tracking list updates.
    "browser.safebrowsing.provider.mozilla.gethashURL" = "";

    # Empties the SafeBrowsing provider's update URL (Mozilla).
    # Removes the endpoint used to fetch updates to Mozilla's tracking protection.
    # Disables the background polling for list changes.
    "browser.safebrowsing.provider.mozilla.updateURL" = "";

    # Enforces HTTPS-Only Mode across the application.
    # Automatically upgrades all HTTP connections to HTTPS, and blocks them if HTTPS isn't available.
    # Prevents plaintext interception of any web resources loaded within Thunderbird.
    "dom.security.https_only_mode" = true;

    # Marks HTTPS-Only Mode as having been enabled.
    # Prevents the application from showing a prompt asking the user to enable it.
    # Ensures the setting stays permanently locked in the user's profile.
    "dom.security.https_only_mode_ever_enabled" = true;

    # Enforces HTTPS-Only Mode in Private Browsing contexts.
    # Extends the mandatory encryption to any ephemeral or private windows opened.
    # Leaves no gaps in the encryption enforcement.
    "dom.security.https_only_mode_pbm" = true;

    # Disables WebRTC peer connections.
    # WebRTC can leak your real local and public IP addresses, even behind a VPN or proxy.
    # Disabling it completely plugs one of the most common de-anonymization vectors.
    "media.peerconnection.enabled" = false;

    # Empties the URL used to scan the local network region.
    # Prevents the application from trying to determine its geographic location via IP or Wi-Fi data.
    # Hardens the location privacy by removing the scanning endpoint.
    "browser.region.network.url" = "";

    # Disables the background region update service.
    # Stops Thunderbird from trying to figure out which country it is operating in.
    # Ensures behavior remains consistent regardless of the physical network location.
    "browser.region.update.enabled" = false;

    # Disables search suggestions in the unified search bar.
    # Prevents everything you type into the search bar from being sent live to a search engine.
    # Crucial for preventing keystroke leakage during local searches.
    "browser.search.suggest.enabled" = false;

    # Disables search suggestions specifically in private browsing windows.
    # Ensures that private mode is truly private and doesn't leak keystrokes.
    # Mirrors the global disablement for completeness.
    "browser.search.suggest.enabled.private" = false;

    # Disables the Web Push API.
    # Prevents websites or services from registering background workers to push notifications.
    # Closes a persistent background connection (websocket) to Mozilla's push servers.
    "dom.push.enabled" = false;

    # Disables the actual network connection used for Web Push.
    # Hardens the disablement by severing the transport layer for push notifications.
    # Ensures zero background keep-alives.
    "dom.push.connection.enabled" = false;

    # Empties the URL of the Web Push server.
    # Provides a final layer of defense by removing the endpoint push services would connect to.
    # Completely incapacitates the push notification infrastructure.
    "dom.push.serverURL" = "";

    # Disables the Battery Status API.
    # Prevents scripts from reading the device's battery level and charging status.
    # Removes a known vector for fingerprinting and cross-site tracking.
    "dom.battery.enabled" = false;

    # Disables the Gamepad API.
    # Prevents access to connected USB controllers or joysticks.
    # Removes another obscure fingerprinting vector used by advanced tracking scripts.
    "dom.gamepad.enabled" = false;

    # Disables the WebVR API.
    # Prevents access to connected virtual reality hardware.
    # Minimizes the attack surface by disabling unused hardware interfaces.
    "dom.vr.enabled" = false;
  };

  mediaPreferences = {
    # Disables the navigator.mediaDevices API.
    # Prevents websites or HTML emails from requesting access to microphones and cameras.
    # Enhances privacy by removing the ability to even prompt for hardware access.
    "media.navigator.enabled" = false;

    # Disables video statistics tracking.
    # Prevents the collection of metrics regarding video playback performance.
    # Removes a minor vector for fingerprinting based on hardware decoding capabilities.
    "media.video_stats.enabled" = false;

    # Disables the GMP (Gecko Media Plugins) provider, often used for DRM (Digital Rights Management).
    # DRM modules are closed-source binaries that can act unpredictably and phone home.
    # Removing them reduces the attack surface and prevents proprietary tracking.
    "media.gmp-provider.enabled" = false;

    # Disables Encrypted Media Extensions (EME), the web standard for DRM.
    # Prevents the playback of DRM-encumbered media, which requires reaching out to license servers.
    # Enhances privacy by blocking interaction with external rights management authorities.
    "media.eme.enabled" = false;

    # Empties the URL used to download and update GMP/DRM modules.
    # Ensures that Thunderbird cannot accidentally fetch these proprietary binaries.
    # Hardens the DRM disablement.
    "media.gmp-manager.url" = "";

    # Disables automatic updates for GMP/DRM modules.
    # Stops any background attempts to refresh these plugins.
    # Further enforces the ban on closed-source media components.
    "media.gmp-manager.updateEnabled" = false;
  };

  uiPreferences = {
    # Disables the automatic guessing of email provider configurations.
    # Prevents Thunderbird from reaching out to Mozilla's ISP database to auto-configure accounts.
    # You must configure IMAP/SMTP manually, preventing leakage of your email domain during setup.
    "mailnews.auto_config.guess.enabled" = false;

    # Disables fetching configuration details from the ISP.
    # Stops Thunderbird from trying common subdomains (e.g., imap.domain.com) to guess settings.
    # Prevents broadcasting your intent to set up an email address to the network.
    "mailnews.auto_config.fetchFromISP.enabled" = false;

    # Disables the Thunderbird start page that normally loads when the app opens.
    # Prevents fetching a webpage from Mozilla every time you launch the application.
    # Ensures a completely offline startup process.
    "mailnews.start_page.enabled" = false;

    # Empties the URL of the Thunderbird start page.
    # Acts as a secondary defense to ensure the start page has nowhere to load from.
    # Keeps the startup view strictly local.
    "mailnews.start_page.url" = "";

    # Disables loading remote images in emails by default.
    # Remote images are the primary mechanism for tracking pixel "read receipts" in emails.
    # Blocking them prevents senders from knowing when, where, and if you opened their email.
    "mailnews.message_display.disable_remote_image" = true;

    # Disables the integrated chat features in Thunderbird (XMPP, Matrix, etc.).
    # We only want this application to be an email and calendar client.
    # Reduces the attack surface and prevents accidental connection to chat networks.
    "mail.chat.enabled" = false;

    # Disables the search for external email providers during account creation.
    # Prevents the "Get a new email address" prompt which queries external services.
    # Ensures the account setup wizard only focuses on adding existing, manually configured accounts.
    "mail.provider.enabled" = false;

    # Hides the Add-ons pane from certain UI elements.
    # Reduces clutter and limits the visibility of the built-in extension marketplace.
    # Encourages centralized extension management via NixOS configuration.
    #"extensions.getAddons.showPane" = false;

    # Disables personalized add-on recommendations on the about:addons page.
    # Prevents fetching recommended extensions from Mozilla's servers based on your profile.
    # Stops unnecessary background connections to the AMO (Add-ons) database.
    "extensions.htmlaboutaddons.recommendations.enabled" = false;

    # Overrides the "know your rights" infobar displayed on first run.
    # Hides the banner linking to Mozilla's privacy policy and rights page.
    # Provides a cleaner, distraction-free first launch.
    "mail.rights.override" = true;

    # Sets the rights version to the current version, fulfilling the requirement.
    # Tricks Thunderbird into thinking the rights banner has already been acknowledged.
    # Permanently suppresses the rights notification.
    "mail.rights.version" = 1;

    # Disables automatic search engine updates.
    # Prevents Thunderbird from periodically reaching out to update its list of search providers.
    # Removes another minor background network connection.
    "browser.search.update" = false;
  };

  updatePreferences = {
    # Disables automatic application updates.
    # On NixOS, the package manager handles updates, so internal app updaters are redundant and noisy.
    # Prevents Thunderbird from constantly polling Mozilla for new versions.
    "app.update.auto" = false;

    # Completely disables the update mechanism framework.
    # Strips out the ability for Thunderbird to even attempt to update itself.
    # Enforces immutable, system-level updates only.
    "app.update.enabled" = false;

    # Disables the automatic updating of system add-ons.
    # System add-ons are hidden extensions pushed by Mozilla for hotfixes or features.
    # Disabling this prevents untracked, silent code changes to the application.
    "extensions.systemAddon.update.enabled" = false;

    # Empties the URL used for updating system add-ons.
    # Guarantees that Thunderbird cannot query or download new system extensions.
    # Ensures the application binary and its components remain immutable.
    "extensions.systemAddon.update.url" = "";

    # Disables automatic updates for standard extensions/add-ons.
    # In a highly secure environment, extensions should be managed and pinned via NixOS.
    # Prevents supply-chain attacks where a compromised extension pushes a malicious update.
    "extensions.update.enabled" = false;

    # Empties the URL used to discover new extensions in the UI.
    # Disables the "Get Add-ons" marketplace functionality within Thunderbird.
    # Prevents users from accidentally browsing or installing unvetted third-party code.
    "extensions.webservice.discoverURL" = "";
  };

in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird system settings";

    dnsOverHttps = {
      enable = lib.mkEnableOption "Enable DNS over HTTPS";

      url = lib.mkOption {
        type = lib.types.str;
        description = "The URL of the DNS over HTTPS server.";
      };
      caCertPath = lib.mkOption {
        type = lib.types.str;
        description = "The absolute path of CA certificate to import required by the DoH servers.";
      };
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable (
    lib.mkMerge [

      # Base Thunderbird Configuration
      {
        programs.thunderbird = {
          enable = true;
          policies = lib.mkMerge [
            appUpdatePolicies
            telemetryPolicies
            uiPolicies
            searchPolicies
          ];
          preferences = lib.mkMerge [
            networkPreferences
            telemetryPreferences
            privacyPreferences
            mediaPreferences
            uiPreferences
            updatePreferences
          ];
        };
      }

      # Conditional DoH Configuration
      (lib.mkIf cfg.dnsOverHttps.enable {
        programs.thunderbird = {
          policies = dohPolicies;
          preferences = dohPreferences;
        };
      })

      # Strict local DNS fallback when DoH is not explicitly enabled
      (lib.mkIf (!cfg.dnsOverHttps.enable) {
        programs.thunderbird = {
          preferences = {
            # Enforces local DNS resolution using the system's resolver exclusively.
            # Mode 5 means TRR is completely disabled, and all DNS requests must use the OS resolver.
            # This ensures no leaks occur if DoH is intentionally turned off.
            "network.trr.mode" = 5;
          };
        };
      })
    ]
  );
}
