{ config, pkgs, ... }:


{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cytopia = {
    isNormalUser = true;
    description = "cytopia";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [];
  };
}
