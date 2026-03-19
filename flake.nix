{
  description = "My NixOS Flake Configuration";

  ###
  ### Inputs
  ###
  inputs = {
    # NixOS: packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # NixOS: Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom: neovim 0.12 overlay
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom: AWS VPN Client flake
    awsvpnclient-nix = {
      url = "github:AddG0/awsvpnclient-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  ###
  ### Outputs
  ###
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
  let
    # Adjust accordingly
    stateVersion = "25.11";
    system = "x86_64-linux";

    # [ADDED] Safely instantiate unstable packages once per system architecture.
    # This allows unfree packages specifically for the unstable branch.
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # [CHANGED] Extracted overlays into a reusable variable instead of instantiating `pkgs` globally.
    # This allows NixOS and Home Manager to build their own `pkgs` with the same rules.
    sharedOverlays = builtins.attrValues (import ./overlays { inherit inputs; });
  in {

    # System (global)
    # sudo nixos-rebuild switch --flake .#host
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      inherit system;

      # Pass inputs and stateVersion to all NixOS modules
      specialArgs = { inherit inputs stateVersion pkgs-unstable; };
      modules = [
        {
          # This is the standard way to apply unfree packages and overlays in Flakes.
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = sharedOverlays;

          # Sync Registry and Nix Path
          nix.registry.nixpkgs.flake = nixpkgs;
          nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

          # Enable Flakes
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          # 1. Ensure the home-manager CLI is installed on the system
          environment.systemPackages = [
            home-manager.packages.${system}.default
          ];
        }

        # Import the AWS VPN module
        inputs.awsvpnclient-nix.nixosModules.default

        # Import the host
        ./hosts/core/default.nix
      ];
    };

    # Home-Manager
    # home-manager switch --flake .#cytopia
    homeConfigurations."cytopia" = home-manager.lib.homeManagerConfiguration {
      # Home Manager standalone requires an instantiated `pkgs`.
      # We instantiate it here specifically for Home Manager, using our shared config.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = sharedOverlays;
      };

      extraSpecialArgs = { inherit inputs stateVersion pkgs-unstable; };
      modules = [ ./modules/home-manager/home.nix ];
    };
  };
}
