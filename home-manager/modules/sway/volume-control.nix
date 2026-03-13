{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "my-volume" (builtins.readFile ./scripts/my-volume.sh))
	pkgs.libnotify  # Provides 'notify-send'
  ];
}
