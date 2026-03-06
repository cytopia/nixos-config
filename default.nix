{ config, lib, pkgs, ... }:

{
  imports = [
    # --- Core modules ---
    ./modules/core/nixos.nix
    ./modules/core/network.nix
    ./modules/core/time-locale.nix
    ./modules/core/keyboard.nix
    ./modules/core/users.nix
    ./modules/core/gpu-intel.nix
    ./modules/core/sound.nix

    # --- GUI modules ---
    ./modules/gui/login-manager.nix
    ./modules/gui/display-manager.nix
    ./modules/gui/sway.nix

    # --- Programs ---
    ./modules/programs/_default.nix
    ./modules/programs/chromium.nix
  ];
}
