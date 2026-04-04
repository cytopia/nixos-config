{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.programs.podman;
in
{
  ###
  ### 1. OPTIONS
  ###
  options.mySystem.programs.podman = {
    enable = lib.mkEnableOption "Rootless Podman container engine";

    dockerCompat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create 'docker' alias and socket for compatibility.";
    };
  };

  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # This ensures that we never have both engines running.
    # We use mkForce to override any other modules.
    virtualisation.docker.enable = lib.mkForce false;

    # This stops the 'nixos-rebuild' before it even starts if there's a conflict.
    assertions = [
      {
        assertion = !(config.virtualisation.docker.enable && cfg.enable);
        message = "Podman and Docker are mutually exclusive in the 'mySystem' architecture. Please disable one.";
      }
    ];

    # --- THE ENGINE ---
    virtualisation.podman = {
      enable = true;
      dockerCompat = cfg.dockerCompat;

      # SECURITY NOTE: This enables the system-wide socket.
      # It allows tools like VSCode to work, but requires 'podman' group membership.
      #dockerSocket.enable = cfg.dockerCompat;

      # Essential for container-to-container DNS resolution
      defaultNetwork.settings.dns_enabled = true;
    };

    # --- INFRASTRUCTURE ---
    # Required for subuid/subgid mappings (Rootless mode)
    virtualisation.containers = {
      enable = true;

      # Force Netavark to use pure nftables,
      # eliminating the legacy iptables-nft translation tables.
      containersConf.settings = {
        network = {
          firewall_driver = "nftables";
        };
      };
    };

    # Automatic Storage Management
    # Containers eat disk space rapidly. This ensures that
    # orphaned layers and stopped containers are cleaned weekly.
    virtualisation.podman.autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };

    # --- TOOLING (Consolidated) ---
    environment.systemPackages = with pkgs; [
      podman-compose

      # ADDITION: The 'Container Trinity'
      # buildah: Optimized for building images without a Dockerfile
      # skopeo: Inspecting remote images without pulling them
      buildah
      skopeo
    ];

    # --- ARCHITECTURAL FIX: NETWORKING & FIREWALL ---
    # Podman 5.0+ (Standard in 2026) uses Netavark/Pasta.
    # To ensure podman-compose works without weird network hangs,
    # we ensure the user is in the 'podman' group.
    #users.groups.podman.members = [ "cytopia" ];

    # ADJUSTMENT: If you use a strict firewall, Podman needs
    # specific rules to allow DNS lookups from containers.
    # We add this here to prevent 'Address not found' errors in containers.
    #networking.firewall.trustedInterfaces = [ "podman0" ];
  };
}
