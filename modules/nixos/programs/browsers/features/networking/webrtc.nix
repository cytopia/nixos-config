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
                # default = WebRTC will use all available interfaces when searching for the best path.
                #
                # default_public_and_private_interfaces = WebRTC will only use the interface
                #   connecting to the public Internet, but may connect using private IP addresses.
                #
                # default_public_interface_only = WebRTC will only use the interface connecting
                #   to the public Internet, and will not connect using private IP addresses.
                #
                # disable_non_proxied_udp = WebRTC will use TCP on the public-facing interface,
                #   and will only use UDP if supported by a configured proxy.
                #   This ensures the real UP is never exposed.
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
