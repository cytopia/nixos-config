{ config, pkgs, ... }:


{
  ###
  ### Login Manager
  ###
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # -t: time, -r: Remember last user, -c: Command to run
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --cmd sway";
        user = "greeter";
        vt = 1;
      };
    };
  };

  # Keep the TUI clean from kernel "noise" during password entering on greetd
  boot.kernelParams = [ "quiet" "splash" ];
}
