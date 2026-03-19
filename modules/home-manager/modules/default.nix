{ config, pkgs, inputs, ... }:
let
  # This imports the unstable channel into a local variable
  unstable = pkgs.unstable;
in
{
  home.packages = with pkgs; [
    unstable.devbox
  ];
}
