{ config, pkgs, ... }:

# https://tsawyer87.github.io/posts/gpg-agent_on_nixos/
{
  ###
  ### Manage SSH keys exclusively
  ###
  services.ssh-agent = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    defaultMaximumIdentityLifetime = 3600; # in seconds
  };

  ###
  ### Manage GPG keys exclusively
  ###
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.program = "pinentry-gnome3";
    pinentry.package = pkgs.pinentry-gnome3;

    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  ###
  ### Additional tools
  ###
  programs.gpg.enable = true;
  home.packages = with pkgs; [
    seahorse
  ];
}

