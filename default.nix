{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/sway.nix
    ./modules/chromium.nix
    #./modules/core.nix
    #./modules/users.nix
    #./modules/packages.nix
    #./profiles/development.nix # Only include what you need
  ];
}
