# nixos-config


## Updates
```
# stage new versions to update
nix flake update

# Update system
sudo nixos-rebuild switch --flake .#$(hostname)

# Update home
home-manager switch --flake .#cytopia

# Restart Nix daemon in case flake update is locked
sudo systemctl restart nix-daemon
```

## Housekeeping

### System
```
# List generations
sudo nixos-rebuild list-generations

# Delete all generations older than 14 days
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations 14d

# Delete ALL generations except the current one
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old

sudo nix-collect-garbage -d
```

### Home-Manager
```
# List generations
home-manager generations

# Delete generations older than 14 days
home-manager expire-generations "-14 days"

nix-collect-garbage -d
```

## Credits

Inpsired by [Misterio77](https://github.com/Misterio77/nix-starter-configs)
