{ config, pkgs, ... }:
let
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  theme = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";
  greeting = "NixOS";

  sway-run = pkgs.writeShellScriptBin "sway-run" ''
    # Export the NixOS system environment variables
    # This replaces the need for 'bash --login'
    #source /etc/set-environment

    # Optional: Manual safety net for the socket
    #export XDG_CURRENT_DESKTOP=sway

    # Launch Sway and redirect logs
	exec sway > /tmp/sway.log 2>&1
  '';
in
{
  ###
  ### Login Manager
  ###
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # -t: time, -r: Remember last user, -c: Command to run
        command = "${tuigreet} --time --theme '${theme}' --greeting ${greeting} --cmd ${sway-run}/bin/sway-run";
        user = "greeter";
        vt = 1;
      };
    };
  };

  # Keep the TUI clean from kernel "noise" during password entering on greetd
  boot.kernelParams = [ "quiet" "splash" ];
}
