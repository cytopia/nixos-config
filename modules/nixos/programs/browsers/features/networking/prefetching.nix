{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.networking.prefetching;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.networking.prefetching = {

            disableNetworkPrediction = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables DNS prefetching and TCP pre-connection (Preloading).
                Prevents the browser from silently resolving domains and opening connections
                to links on a webpage before you actually click them. Highly recommended
                for strict privacy to prevent leaking your IP address to third-party servers
                and to reduce unnecessary background network traffic.
              '';
            };

          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableNetworkPrediction {
                # 0 = Always predict
                # 1 = Predict on Wi-Fi only
                # 2 = Never predict (Strict Privacy)
                "NetworkPredictionOptions" = 2;
              })
            ];
          };
        }
      )
    );
  };
}
