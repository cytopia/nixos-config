{ config, pkgs, ... }:


{
  # Configure the TTY keyboard layout
  console = {
    keyMap = "us";
  };

  # Adjust keyboard repeat rate
  systemd.services.set-kdb-rate = {
    description = "Set the keyboard repeat rate";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 250 -r 50";
      StandardOutput = "null"; # Keeps your TTY boot clean
    };
  };
}

