# nixos-config


## TL;DR
```bash
# Update
nix flake update
sudo nixos-rebuild switch --flake .#$(hostname)
home-manager switch --flake .#cytopia@$(hostname)

# Cleanup System
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
sudo nix-collect-garbage
sudo /run/current-system/bin/switch-to-configuration boot

# Cleanup Home Manager
home-manager expire-generations "-14 days"
nix-collect-garbage
```


## Updates
```bash
# stage new versions to update
nix flake update

# Update system
sudo nixos-rebuild switch --flake .#$(hostname)
sudo nixos-rebuild switch --flake .#$(hostname) --offline

sudo nixos-rebuild switch --flake .#$(hostname) --rollback

# Update home
home-manager switch --flake .#cytopia@$(hostname)

# Restart Nix daemon in case flake update is locked
sudo systemctl restart nix-daemon
```

## Housekeeping

### System
```bash
# List generations
sudo nixos-rebuild list-generations

# Delete all generations older than 14 days
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations 14d

# Delete all except last 5 generations
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5

# Delete ALL generations except the current one
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old

# Remove cleaned generations
sudo nix-collect-garbage

# Remove all unlinked generations
sudo nix-collect-garbage -d

# Remove old boot files
sudo nixos-rebuild boot --flake .#$(hostname)
```

### Home-Manager
```bash
# List generations
home-manager generations

# Delete generations older than 14 days
home-manager expire-generations "-14 days"

nix-collect-garbage -d
```

### Validation
```bash
nix store verify --all
```

### System info
```bash
# Get latest build kernel
ls -lap /run/current-system/kernel

# List all installed system packages
nix-store -q --references /run/current-system/sw \
  | sed 's|^/nix/store/[a-z0-9]\{32\}-||' \
  | sort
```

## Credits

Inspired by [Misterio77](https://github.com/Misterio77/nix-starter-configs)
