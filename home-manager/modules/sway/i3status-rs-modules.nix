{ pkgs, ... }:
let
  scriptName = "i3status-rs-bluetooth.sh";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin scriptName (builtins.readFile ./scripts/i3status-rs-bluetooth.sh))
  ];
}
