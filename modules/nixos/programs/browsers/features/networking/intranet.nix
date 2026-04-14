{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.networking.intranet;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.networking.intranet = {

            blockPublicToPrivateRouting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Implements "Private Network Access" (PNA) restrictions.
                Strictly blocks public internet websites from making Cross-Site Request Forgery (CSRF)
                requests to your local network (192.168.x.x) and loopback address (127.0.0.1).
                Prevents malicious sites from scanning your home for smart devices or attacking
                local developer servers.
              '';
            };

            disableMediaRouter = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables the Chromecast and Media Router discovery protocols (mDNS/SSDP).
                Stops the browser from constantly broadcasting multicast packets to scan
                your local network for castable TVs and speakers.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {
            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.blockPublicToPrivateRouting {
                # Blocks public sites from hitting local IPs
                "LocalNetworkAccessBlockedForUrls" = [ "*://*" ];
                # Blocks public sites from hitting localhost
                "LoopbackNetworkBlockedForUrls" = [ "*://*" ];
              })

              (lib.mkIf cfg.disableMediaRouter {
                # Kills mDNS broadcasting
                "EnableMediaRouter" = false;
              })
            ];
          };
        }
      )
    );
  };
}
