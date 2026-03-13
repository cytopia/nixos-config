{ pkgs, ... }:
let
  scriptName = "my-microphone";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin scriptName (builtins.readFile ./scripts/my-microphone.sh))
	pkgs.libnotify  # Provides 'notify-send'
  ];
}
