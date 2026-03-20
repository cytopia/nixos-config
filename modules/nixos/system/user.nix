{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.system.user;
in
{

  ###
  ### 1. OPTIONS
  ###
  options.mySystem.system.user = {
    enable = lib.mkEnableOption "System user management";

    name = lib.mkOption {
      type = lib.types.str;
      description = "The username of the primary system user.";
    };

    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 1000;
      description = "The User ID. Static IDs prevent permission issues across machines.";
    };

    # NixOS uses group 100 by default
    #gid = lib.mkOption {
    #  type = lib.types.nullOr lib.types.int;
    #  default = 1000;
    #  description = "The Group ID for the user's primary group.";
    #};

    home = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null; # Defaults to /home/${name} if null
      description = "Path to the user's home directory.";
    };

    homeMode = lib.mkOption {
      type = lib.types.str;
      default = "0700"; # Private by default
      description = "Permissions for the home directory (e.g., '0700' for private, '0755' for public).";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "Primary User Account";
      description = "The GECOS field (full name/description) for the user.";
    };

    shell = lib.mkOption {
      description = "The default shell for the user.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional groups to append to the standard power-user set.";
    };

    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Public SSH keys for authorized_keys.";
    };
  };


  ###
  ### 2. CONFIGURATION
  ###
  config = lib.mkIf cfg.enable {

    # Set the default shell here. This allows pkgs to be fully resolved
    # before this value is merged.
    mySystem.system.user.shell = lib.mkDefault pkgs.bash;

	programs.zsh.enable = lib.mkIf (lib.getName cfg.shell == "zsh") true;
	programs.bash.enable = lib.mkIf (lib.getName cfg.shell == "bash") true;

    # Define the primary group explicitly if a GID is provided
    #users.groups.${cfg.name} = lib.mkIf (cfg.gid != null) {
    #  gid = cfg.gid;
    #};

    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.description;
      shell = cfg.shell;

      uid = lib.mkIf (cfg.uid != null) cfg.uid;
      #group = cfg.name; # Links to the group defined above
      home = if cfg.home != null then cfg.home else "/home/${cfg.name}";
      createHome = true;
      homeMode = cfg.homeMode;

      # Core groups for a modern Linux workstation
      extraGroups = [
        "audio"           # PipeWire access
        "video"           # Hardware acceleration (Intel/VBox GPU)
        "input"           # Libinput/Keyboard/Mouse access
        "render"          # GPU Acceleration
      ] ++ cfg.extraGroups;

      openssh.authorizedKeys.keys = cfg.sshKeys;

      # Tip: We keep password management out of the flake for security.
      # You can set it manually via 'sudo passwd <username>' on first boot.
    };

    # Automatically set the 'initialPassword' for a new install if you wish.
    # users.users.${cfg.name}.initialPassword = "nixos";
  };
}
