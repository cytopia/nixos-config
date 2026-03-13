{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "my-microphone" (builtins.readFile ./scripts/my-microphone.sh))
	pkgs.libnotify  # Provides 'notify-send'
  ];
}
