{ config, pkgs, pkgs-unstable, inputs, ... }:
{
  home.packages = with pkgs; [
    pkgs-unstable.swayimg
    pinta
    drawing  # gnome Drawing (ms-paint like)
  ];
}


