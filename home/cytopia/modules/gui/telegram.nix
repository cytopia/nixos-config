{ config, pkgs, pkgs-unstable, inputs, ... }:
{
  home.packages = with pkgs; [
    pkgs-unstable.telegram-desktop
  ];
}

