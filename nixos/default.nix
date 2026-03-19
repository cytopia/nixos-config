{ config, lib, pkgs, ... }:

{
  imports = [
    # --- NixOS ---
    ./modules/nixos/nix.nix

    # --- Core modules ---
    ./modules/core/network.nix
    ./modules/core/time-locale.nix
    ./modules/core/keyboard.nix
    ./modules/core/users.nix
    ./modules/core/gpu-intel.nix
    ./modules/core/bluetooth.nix
    ./modules/core/sound.nix
    ./modules/core/power-management.nix

    # --- CLI modules ---
    ./modules/cli/vim.nix

    # --- GUI modules ---
    ./modules/gui/fonts.nix
    ./modules/gui/login-manager.nix
    ./modules/gui/display-manager.nix
    ./modules/gui/sway.nix

    # --- Programs ---
    ./modules/programs/_default.nix
    ./modules/programs/chromium.nix
    ./modules/programs/thunar.nix
    ./modules/programs/podman.nix
    ./modules/programs/obs.nix
  ];

  #networking.mobileWorkstation.profile = "hardened";

  environment.systemPackages = [
	pkgs.steam-run
  ];
  qt.enable = true;

  # Might help chromium errors and screensharing
  fonts.fontconfig.enable = true;
}
