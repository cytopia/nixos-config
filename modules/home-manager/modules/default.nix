{ config, pkgs, inputs, ... }:
let
  # This imports the unstable channel into a local variable
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with pkgs; [
    unstable.devbox
  ];
}
