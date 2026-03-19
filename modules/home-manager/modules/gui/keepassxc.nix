{ config, pkgs, ... }:

{

  home.packages = with pkgs; [
    keepassxc
  ];

  # Unfortunately the following gives me 'access error on ~.config/keepassxc/keepassxc.ini'
  # So I cannot configure it via Nix

  #programs.keepassxc = {
  #  # When this flag is set, KeePassXC' builtin native messaging manifest for communication
  #  # with its browser extension is automatically installed.
  #  # This conflicts with KeePassXC' builtin installation mechanism.
  #  # To prevent error messages, set programs.keepassxc.settings.Browser.UpdateBinaryPath to false
  #  enable = true;
  #  settings = {
  #    Browser.UpdateBinaryPath = false;
  #    GUI = {
  #      AdvancedSettings = true;
  #      ApplicationTheme = "dark";
  #      CompactMode = true;
  #      HidePasswords = true;
  #    };

  #    SSHAgent.Enabled = false;
  #  };
  #};
}

