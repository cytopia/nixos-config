{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.networking.ntp;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.networking.ntp = {

            disableNetworkTimeSync = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Stops Chrome from silently making background network requests to Google's
                time servers to sync the browser clock.

                Note: Disabling this prevents the browser from "phoning home" for time,
                but ensure your System Clock is accurate via NixOS (services.chrony/ntp),
                otherwise SSL certificate validation may fail.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableNetworkTimeSync {
                # This policy controls whether the browser can use the network to
                # retrieve the current time from Google servers to verify SSL certs
                # and internal timers. Setting this to false forces the browser to
                # trust the local system clock exclusively.
                "BrowserNetworkTimeQueriesEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
