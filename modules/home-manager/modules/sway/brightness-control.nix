{ pkgs, ... }:
let
  scriptName = "my-brightness";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin scriptName (builtins.readFile ./scripts/my-screen-brightness.sh))
	pkgs.libnotify  # Provides 'notify-send'
  ];
}
