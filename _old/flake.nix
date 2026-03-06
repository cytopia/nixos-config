{
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.generic-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 1. This pulls in the LUKS line and the imports list from the fresh install
        /etc/nixos/configuration.nix

        # 2. This pulls in your generic, portable settings
        ./my-generic-logic.nix

        # 3. (Optional) Force-enable flakes so you never have to edit the file
        { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
      ];
    };
  };
}
