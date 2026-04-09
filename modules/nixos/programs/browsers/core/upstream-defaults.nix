{ lib, ... }:

let
  # ===========================================================================
  # UPSTREAM DEFAULT DICTIONARIES
  # These ensure the base derivations do not lose their required stability flags
  # when our wrapper takes over the command line arguments.
  #
  # NOTE: Do NOT include dynamic runtime flags here (like origin-trial-keys
  # or render-node-overrides). Chromium handles those internally.
  # ===========================================================================

  braveDefaults = {
    flags = [ ]; # Flags are always additive
    enableFeatures = [
      # Standard NixOS baseline for Brave hardware acceleration
      "VaapiVideoDecoder"
      "VaapiVideoEncoder"
    ];
    disableFeatures = [
      # Prevents Brave from complaining if Nixpkgs hasn't updated in a while
      "OutdatedBuildDetector"
      # Deprecated ChromeOS decoder that Nixpkgs specifically disables
      "UseChromeOSDirectVideoDecoder"
    ];
  };

  chromeDefaults = {
    flags = [ ]; # Flags are always additive
    enableFeatures = [ ];
    disableFeatures = [ ];
  };

  chromiumDefaults = {
    flags = [ ]; # Flags are always additive
    enableFeatures = [ ];
    disableFeatures = [ ];
  };

in
{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        let
          defaults =
            if name == "brave" then
              braveDefaults
            else if name == "google-chrome" then
              chromeDefaults
            else
              chromiumDefaults;
        in
        {
          config = {
            internal.flags = defaults.flags;
            internal.enableFeatures = defaults.enableFeatures;
            internal.disableFeatures = defaults.disableFeatures;
          };
        }
      )
    );
  };
}
