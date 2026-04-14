{
  lib,
  config,
  ...
}:

let
  # The Submodule definition: Every browser gets its own isolated bus.
  browserModule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "this specific browser framework";

      # =========================================================
      # THE INTERNAL BUS (Instantiated PER browser)
      # =========================================================
      internal = {
        flags = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; internal = true; };
        enableFeatures = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; internal = true; };
        disableFeatures = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; internal = true; };
        envVars = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; internal = true; };

        policies = lib.mkOption { type = lib.types.attrs; default = { }; internal = true; };
        initialPreferences = lib.mkOption { type = lib.types.attrs; default = { }; internal = true; };
        runScripts = lib.mkOption { type = lib.types.lines; default = ""; internal = true; };

        # Allows features to register background services (like cert sync)
        systemdUserServices = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          internal = true;
        };
      };
    };
  };
in
{
  imports = [
    # Reqiured core functionality
    ./core/wrapper.nix
    ./core/upstream-defaults.nix

    # Optional self-contained default features
    ./features/extensions.nix
    ./features/preferences.nix
    ./features/scaling.nix
    ./features/search.nix
    ./features/startup.nix
    ./features/certificates.nix

    # Optional self-contained hardware acceleration features
    ./features/hardware/display.nix
    ./features/hardware/driver-overrides.nix
    ./features/hardware/graphics.nix
    ./features/hardware/machine-learning.nix
    ./features/hardware/memory.nix
    ./features/hardware/rasterization.nix
    ./features/hardware/video.nix

    # Optional self-contained networking features
    ./features/networking/dns.nix
    ./features/networking/ntp.nix
    ./features/networking/intranet.nix
    ./features/networking/prefetching.nix
    ./features/networking/webrtc.nix

    # Optional self-contained privacy features
    ./features/privacy/identity.nix
    ./features/privacy/local-state.nix
    ./features/privacy/remote-services.nix
    ./features/privacy/telemetry.nix
    ./features/privacy/web-tracking.nix

    # Optional self-contained security features
    ./features/security/attack-surface.nix
    ./features/security/engine-isolation.nix
    ./features/security/site-permissions.nix
    ./features/security/system-integration.nix
    ./features/security/tls.nix

    # Optional self-contained ai features
    ./features/ai/creative-ui.nix
    ./features/ai/developer.nix
    ./features/ai/gemini.nix
    ./features/ai/generative-productivity.nix
    ./features/ai/on-device.nix
  ];

  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule browserModule);
    default = { };
    description = "Attribute set of browsers. Keys MUST be 'chromium', 'brave', or 'google-chrome'.";
  };

  config = {
    # This assertion physically blocks the user from typing anything other than the allowed 3 browsers.
    assertions = [
      {
        assertion = builtins.all (name: builtins.elem name [ "chromium" "brave" "google-chrome" ]) (builtins.attrNames config.cytopia.programs.browsers);
        message = "cytopia.programs.browsers: Keys must be exactly 'chromium', 'brave', or 'google-chrome'.";
      }
    ];
  };
}
