{ config, pkgs, ... }:
let
  # This imports the unstable channel into a local variable
  unstable = import <unstable> {
    config = config.nixpkgs.config; # Inherits your allowUnfree settings
  };
in
{
  home.packages = with pkgs; [
    unstable.swayimg
    pinta
    drawing  # gnome Drawing (ms-paint like)
  ];
}


