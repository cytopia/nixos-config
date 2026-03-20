{ config, pkgs, ... }:


{
  # Enable common container config files and subuid/subgid mappings
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;

    # Create a `docker` alias for podman, so commands like `docker run` work
    dockerCompat = true;

    # Required for containers under podman-compose to be able to talk to each other
    defaultNetwork.settings.dns_enabled = true;
  };

  # (Optional) Install podman-compose system-wide so all users have access to it
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}

