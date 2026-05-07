{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swayimg    # Viewer
    drawing  # gnome Drawing (ms-paint like)
    gimp
  ];

  # TODO: once swayimg is on 5.x, also add config
}
