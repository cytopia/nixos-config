{
  pkgs,
  ...
}:
{
  imports = [
    # Hardware
    ./hardware/gpu-intel.nix
    ./hardware/gpu-virtualbox.nix
    ./hardware/bluetooth.nix

    # System
    ./system/keyboard.nix
    ./system/locale.nix
    ./system/fonts.nix
    ./system/user.nix
    ./system/keyring.nix

    # Networking
    ./networking/simple.nix
    ./networking/services/ntp/default.nix
    ./networking/services/dns/default.nix

    # Services
    ./services/power-management.nix
    ./services/sound.nix
    ./services/login.nix

    # Desktop
    ./desktop/wayland.nix
    ./desktop/sway.nix

    # Programs
    ./programs/chromium.nix
    ./programs/google-chrome.nix
    ./programs/obs.nix
    ./programs/podman.nix
    ./programs/thunar.nix
    ./programs/thunderbird.nix
    ./programs/vim.nix

    # Utils
    ./utils/camera-toggle.nix
  ];
}
