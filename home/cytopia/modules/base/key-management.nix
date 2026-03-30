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
    # We let KeePassXC handle the ssh keys.
    # Lifetime should be null so that ssh keys are available
    # as long as the database is unlocked.
    defaultMaximumIdentityLifetime = null;
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

