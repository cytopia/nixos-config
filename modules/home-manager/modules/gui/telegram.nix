{ config, pkgs, inputs, ... }:
#let
#  unstable = pkgs.unstable;
#in
{
  home.packages = with pkgs; [
    unstable.telegram-desktop
  ];
}

