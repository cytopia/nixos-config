{ config, pkgs, ... }:

# https://gist.github.com/SilentQQS/b23c28889cb957088ecf382400ad4325

let
  chromiumFlags = [
    "--ozone-platform=wayland"
    "--ozone-platform-hint=auto"
    "--enabe-features=TouchpadOverscrollHistoryNavigation,WaylandWindowDecorations"
    "--enable-wayland-ime"
    # Fix: GL
    "--use-gl=angle"
    "--use-angle=gles"
    # Vulkan (breaks video encoding)
    #"--use-angle=vulkan"
    "--enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workarounds"
    # Fix: Video encoding
    "--enable-features=AcceleratedVideoEncoder"
    "--enable-zero-copy"
    # Enables GPU rasterization on all pages
    "--enable-gpu-rasterization"
    # Enable TreesInViz (breaks video encoding)
    #"--enable-features=TreesInViz"

  ];
in
{
  nixpkgs.overlays = [
    (self: super: {
      chromium = pkgs.ungoogled-chromium;
      ungoogled-chromium = super.ungoogled-chromium.override {
        commandLineArgs = chromiumFlags;
      };
    })
  ];

  programs.chromium = {
    enable = true;

    # This is where the magic happens:
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
    };
  };
}
