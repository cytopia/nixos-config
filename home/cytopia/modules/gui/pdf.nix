{ pkgs, ... }:
{
  home.packages = with pkgs; [
    evince
    xournalpp
  ];
}
