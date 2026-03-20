# nixos-config


## Updates
```
# stage new versions to update
nix flake update

# Update system
sudo nixos-rebuild switch --flake .#host

# Update home
home-manager switch --flake .#cytopia
```

## Logs
```
# Session
journalctl -u greetd
```


## Credits

Inpsired by [Misterio77](https://github.com/Misterio77/nix-starter-configs)
