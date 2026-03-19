{ config, pkgs, inputs, ... }:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with pkgs; [
    unstable.telegram-desktop
  ];
}

