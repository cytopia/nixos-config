{ config, pkgs, ... }:


{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cytopia = {
    isNormalUser = true;
    description = "cytopia";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "render"
      "video"
      "wheel"
    ];
    packages = with pkgs; [];
  };
}
