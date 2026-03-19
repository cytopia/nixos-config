{
  description = "My NixOS Flake Configuration";

  inputs = {
    # This pulls the standard NixOS packages
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Match your existing 25.11 system
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

	nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # Bleeding edge

    # Add this input
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";


    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # This pulls the AWS VPN Client flake
    awsvpnclient-nix = {
      url = "github:AddG0/awsvpnclient-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, nixpkgs, nixpkgs-unstable, neovim-nightly, home-manager, awsvpnclient-nix, ... }@inputs:
  let
    # Load our custom overlays from the directory
    myOverlays = import ./overlays { inherit inputs; };
  in {

    # This allows: sudo nixos-rebuild switch --flake .#host
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
      modules = [
        # This imports your existing configuration
        ./hosts/core/default.nix

        # This imports the AWS VPN module
        awsvpnclient-nix.nixosModules.default

        # This enables the AWS VPN program
        {
          nixpkgs.config.allowUnfree = true;

          # Enable Flakes & Registry
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nix.registry.nixpkgs.flake = nixpkgs;

          # 1. Ensure the home-manager CLI is installed on the system
          environment.systemPackages = [
            home-manager.packages.x86_64-linux.default
          ];
          # TODO: Move this somewhere else
          programs.awsvpnclient.enable = true;
        }
      ];
    };

    # This allows: home-manager switch --flake .#cytopia
    homeConfigurations."cytopia" = home-manager.lib.homeManagerConfiguration {
      # Default packages
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = myOverlays.modifications;
      };
      # Everything in here is passed to the modules as an argument
      extraSpecialArgs = {
        inherit inputs;
        # Define pkgs-unstable here so your home.nix can see it
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = myOverlays.modifications;
        };
      };

      modules = [ ./modules/home-manager/home.nix ];
    };



  };
}
