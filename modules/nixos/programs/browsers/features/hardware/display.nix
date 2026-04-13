{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.display;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.display = {

            displayServer = lib.mkOption {
              type = lib.types.enum [
                "wayland"
                "xwayland"
              ];
              default = "wayland";
              description = ''
                The display server protocol Chrome should use.
                Defaults to "wayland" to force native rendering, which is required for crisp
                fractional scaling.
                If you are using Intel Xe driver and encounter many EGL context crashes,
                which affects performance, set this to xwayland.
              '';
            };

            forcePipeWire = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Forces Wayland native screen sharing.
                Ensures Wayland uses the modern, efficient PipeWire backend instead of legacy
                X11 screen grabbing, which often results in black screens on modern compositors.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.mkIf (cfg.displayServer == "wayland") [
                "--ozone-platform=wayland"
                "--ozone-platform-hint=wayland"
              ])
              (lib.mkIf (cfg.displayServer == "xwayland") [
                "--ozone-platform=x11"
              ])
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.forcePipeWire [
                "WebRTCPipeWireCapturer"
              ])
              (lib.mkIf (cfg.displayServer == "wayland") [
                # Tells Wayland (Sway/Hyprland) to handle the window borders cleanly.
                "WaylandWindowDecorations"
              ])
            ];
          };
        }
      )
    );
  };
}
