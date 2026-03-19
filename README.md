# nixos-config

## Directory Structure:

https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix

Make the hostname dynamic:

https://gemini.google.com/app/34a7df97926ee263


## Updates
```
# stage new versions to update
nix flake update

# Update system
sudo nixos-rebuild switch --flake .#host

# Update home
home-manager switch --flake .#cytopia
```
