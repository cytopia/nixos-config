{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swayimg    # Viewer
    drawing  # gnome Drawing (ms-paint like)
    gimp
  ];

  # swayimg >= 5.0 is configured via Lua: dotfiles/swayimg/init.lua
  # (symlinked to ~/.config/swayimg by dotfiles/install.sh).
}
