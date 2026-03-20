{ pkgs, ... }:
let
  scriptName = "my-volume";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin scriptName (builtins.readFile ./scripts/my-volume.sh))
	pkgs.libnotify  # Provides 'notify-send'
  ];
}
