{ pkgs, lib, ... }:

let
  # The script itself
  myScript = pkgs.writeShellApplication {
    name = "colorpicker";
    runtimeInputs = [
      pkgs.hyprpicker
      pkgs.yad
    ];
    text = ''
      COLOR=$(hyprpicker) && yad --color --init-color="$COLOR" --title="colorpicker"
    '';
  };

  # The desktop entry
  myDesktopItem = pkgs.makeDesktopItem {
    name = "colorpicker";
    desktopName = "Colorpicker";
    exec = "${myScript}/bin/colorpicker";
    icon = "system-run";
    categories = [ "Utility" ];
    terminal = false;
  };
in
# The final bundle
pkgs.symlinkJoin {
  name = "colorpicker";
  paths = [
    myScript
    myDesktopItem
  ];

  meta = with lib; {
    description = "My custom script bundled with a desktop entry";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
