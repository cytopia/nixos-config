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

    # Custom: neovim 0.12 overlay (not pinned to nixpkgs)
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

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

    # Every machine is defined here with its architecture and user.
    myHosts = {
      host = { system = "x86_64-linux"; user = "cytopia"; };
      # Example of scaling: satellite = { system = "aarch64-linux"; user = "alice"; };
    };

    # Extracted overlays into a reusable variable instead of instantiating `pkgs` globally.
    # This allows NixOS and Home Manager to build their own `pkgs` with the same rules.
    sharedOverlays = builtins.attrValues (import ./overlays { inherit inputs; });
  in {

    # System (global)
    # sudo nixos-rebuild switch --flake .#host
    # It loops over `myHosts`. The key becomes `hostname` (e.g., "core"),
    # the value becomes `hostConfig` (e.g., { system = "..."; user = "..."; }).
    nixosConfigurations = nixpkgs.lib.mapAttrs (hostname: hostConfig:
      nixpkgs.lib.nixosSystem {
        # Dynamically fetch the system architecture for this specific host
        system = hostConfig.system;

        # Pass variables to NixOS modules dynamically
        specialArgs = {
          inherit inputs stateVersion hostname;
          username = hostConfig.user;

          # Safely instantiate unstable packages for THIS specific architecture
          pkgs-unstable = import nixpkgs-unstable {
            system = hostConfig.system;
            config.allowUnfree = true;
          };
        };

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
              home-manager.packages.${hostConfig.system}.default
            ];
          }

          # Import the AWS VPN module
          inputs.awsvpnclient-nix.nixosModules.default

          # Import hosts dynamically
          ./hosts/${hostname}/default.nix
        ];
      }
    ) myHosts; # Pass myHosts dictionary into mapAttrs

    # Home-Manager
    # home-manager switch --flake .#cytopia
    # We transform the `myHosts` dictionary into `{ name = "cytopia"; value = config; }`
    # and use `listToAttrs` to build the homeConfigurations block.
    homeConfigurations = builtins.listToAttrs (
      nixpkgs.lib.mapAttrsToList (hostname: hostConfig: {
        # The key (name) in homeConfigurations is the username
        name = hostConfig.user;

        # The value is the actual configuration
        value = home-manager.lib.homeManagerConfiguration {

          # Home Manager standalone requires an instantiated `pkgs`.
          # We instantiate it here specifically for Home Manager, using our shared config.
          pkgs = import nixpkgs {
            system = hostConfig.system;
            config.allowUnfree = true;
            overlays = sharedOverlays;
          };
          extraSpecialArgs = {
            inherit inputs stateVersion hostname;
            username = hostConfig.user;

            # Safely instantiate unstable packages for THIS specific architecture
            pkgs-unstable = import nixpkgs-unstable {
              system = hostConfig.system;
              config.allowUnfree = true;
            };
          };
          # Import the user's home configuration dynamically
          modules = [ ./home/${hostConfig.user}/home.nix ];
        };
      }) myHosts # Pass myHosts dictionary into mapAttrsToList
    );
  };
}
