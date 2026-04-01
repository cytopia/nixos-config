{ lib, ... }:
let

  # --- LAYER 1: REFERRER PRIVACY
  disableCrossOriginReferrer = {
    flags = [ ];
    enableFeatures = [
      "NoCrossOriginReferrers" # Block "Referer" header entirely across different domains.
      "MinimalReferrers" # Only send domain in "Referer" if referer is set
    ];
    disableFeatures = [ ];
  };

  # --- LAYER 2: OS & SYSTEM ISOLATION
  isolateSystemEnvironment = {
    flags = [
      # Forces Chrome to use a dummy, isolated local file instead of hooking into your Linux OS keyring (GNOME Keyring/KWallet/Sway).
      # Prevents annoying OS unlock popups, which is ideal since password saving is disabled via policy and handled by the 1Password extension.
      "--password-store=basic"
    ];
    enableFeatures = [
      # Strips details from the User Agent string and Javascript API.
      # It stops websites from seeing your exact CPU model or specific Linux distro version,
      # making you look like a "Generic Linux User."
      "ReducedSystemInfo"
    ];
    disableFeatures = [ ];
  };
  # --- LAYER 3: BACKGROUND TELEMETRY
  # Kills "phone-home" traffic and background analytics.
  disableBackgroundTelemetry = {
    flags = [
      # Disables HTML5 <a ping>. Prevents background POST requests to trackers when you click a link.
      "--no-pings"
      # Stops Chrome from sending diagnostic data to Google when a page fails to load or has SSL errors.
      "--disable-domain-reliability"
      # Disables the local heuristic engine that scans page DOMs for phishing (Saves CPU & improves privacy).
      "--disable-client-side-phishing-detection"
    ];
    enableFeatures = [ ];
    disableFeatures = [ ];
  };

  # --- LAYER 4: TRACKING & IDENTITY
  # Blocks modern browser-level tracking APIs and federated login prompts.
  disableTrackingAPIs = {
    flags = [ ];
    enableFeatures = [ ];
    disableFeatures = [
      # Disables the "Privacy Sandbox" (FLoC/Topics). Stops Chrome from locally profiling your interests for ads.
      "PrivacySandboxAdsAPIs"
      # Blocks "Sign in with Google" popups and prevents identity providers from tracking you across domains.
      "FedCm"
    ];
  };

in
{
  # The New Privacy Function
  getFlags =
    {
      # Layer 1: Controls URL metadata leaks during navigation
      enableReferrerPrivacy ? true,

      # Layer 2: Severs OS/Hardware links (ReducedSystemInfo, basic-store)
      enableSystemIsolation ? true,

      # Layer 3: Kills Hyperlink Auditing and Background Telemetry
      enableBackgroundTelemetryRemoval ? true,

      # Layer 4: Blocks Google's modern browser-level tracking (FLoC/FedCm)
      enableTrackingApiRemoval ? true,
    }:
    let
      # Empty block for falsy conditions
      empty = {
        flags = [ ];
        enableFeatures = [ ];
        disableFeatures = [ ];
      };

      # Map the toggles to our data blocks
      activeBlocks = [
        (if enableReferrerPrivacy then disableCrossOriginReferrer else empty)
        (if enableSystemIsolation then isolateSystemEnvironment else empty)
        (if enableBackgroundTelemetryRemoval then disableBackgroundTelemetry else empty)
        (if enableTrackingApiRemoval then disableTrackingAPIs else empty)
      ];
    in
    {
      flags = lib.concatLists (map (x: x.flags) activeBlocks);
      enableFeatures = lib.concatLists (map (x: x.enableFeatures) activeBlocks);
      disableFeatures = lib.concatLists (map (x: x.disableFeatures) activeBlocks);
    };
}
