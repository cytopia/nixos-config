# Seeds the default sway wallpaper.
#
# Copies the bundled nixos.png into ~/Pictures/wallpapers and points the
# "current" symlink at it. Both targets are create-only: an existing file or
# symlink (even a dangling one) is never touched, so the user may replace the
# image or repoint "current" at any other picture.
#
# Consumed by dotfiles/sway/config:
#   output * bg /home/cytopia/Pictures/wallpapers/current fill
{ config, lib, ... }:
let
  wallpaper = ./wallpapers/nixos.png;
  dir = "${config.xdg.userDirs.pictures}/wallpapers";
in
{
  home.activation.seedWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${dir}"

    if [ ! -e "${dir}/nixos.png" ] && [ ! -L "${dir}/nixos.png" ]; then
      $VERBOSE_ECHO "Seeding ${dir}/nixos.png"
      run cp --no-preserve=mode "${wallpaper}" "${dir}/nixos.png"
    fi

    if [ ! -e "${dir}/current" ] && [ ! -L "${dir}/current" ]; then
      $VERBOSE_ECHO "Linking ${dir}/current -> nixos.png"
      run ln -s nixos.png "${dir}/current"
    fi
  '';
}
