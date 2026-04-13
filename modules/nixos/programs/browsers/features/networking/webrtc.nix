{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.networking.webrtc;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.networking.webrtc = {

            preventIpLeaks = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces WebRTC to only use proxied connections.
                Strictly prevents WebRTC from leaking your local LAN IP and your real ISP IP
                when connected to a VPN.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.preventIpLeaks {
                # The modern, unified policy that replaces the deprecated boolean toggles.
                # "disable_non_proxied_udp" forces WebRTC to use either UDP SOCKS proxying
                # or fallback to TCP proxying, ensuring your real IP is never exposed.
                "WebRtcIPHandling" = "disable_non_proxied_udp";

                # Restrict the UDP port range to 0 to effectively force TCP fallback
                "WebRtcUdpPortRange" = "0-0";
              })
            ];
          };
        }
      )
    );
  };
}
