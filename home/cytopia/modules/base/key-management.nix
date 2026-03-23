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
    defaultMaximumIdentityLifetime = 3600; # in seconds
  };

  # Tell OpenSSH how to prompt you for passwords in Wayland
  home.sessionVariables = {
    # Point SSH to wayprompt's dedicated askpass binary
    SSH_ASKPASS = "${pkgs.wayprompt}/bin/wayprompt-ssh-askpass";

    # IMPORTANT BEHAVIOR NOTE:
    # By default, OpenSSH only uses the GUI askpass if you run SSH via a
    # background program (like git in VSCode). If you run `ssh` in a terminal,
    # it will prompt you in the terminal.
    # Uncomment the line below if you want to FORCE the Wayprompt GUI
    # to appear even when you are typing `ssh` directly in your terminal:
    # SSH_ASKPASS_REQUIRE = "prefer";
  };

  ###
  ### Manage GPG keys exclusively
  ###
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.program = "${pkgs.wayprompt}/bin/wayprompt-gpg-pinentry"; # Be specific
    pinentry.package = pkgs.wayprompt;

    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # This is now done on system-level
  ###
  ### Only manage secrets
  ###
  #services.gnome-keyring = {
  #  enable = true;
  #  # CRITICAL: We only enable "secrets" (for passwords/Seahorse).
  #  # We explicitly leave out "ssh" so it doesn't fight your real ssh-agent.
  #  components = [ "secrets" ];
  #};

  programs.wayprompt = {
    enable = true;
    settings = {
      general = {
        font-regular = "sans:size=14";
        pin-square-amount = 32;
      };
      colours = {
        background = "ffffffaa";
      };
    };
  };


  ###
  ### Additional tools
  ###
  programs.gpg.enable = true;
  home.packages = with pkgs; [
    seahorse
  ];
}

