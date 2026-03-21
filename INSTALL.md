# Install


## Disk setup

```bash
# Fetch from the internet
sudo nix run github:nix-community/disko -- --mode disko --flake github:cytopia/nixos-config#shell

# Fetch from current directory
sudo nix run github:nix-community/disko -- --mode disko --flake .#shell


sudo nix run github:nix-community/disko -- --mode disko ./disko-config.nix
```


```

# Connect to internet (or use graphical install to connect to WiFi)
nmcli device wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Format the disk
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:cytopia/nixos-config#shell

# (only needs to be done once per hardware)
sudo mkdir -p /mnt/etc/nixos
sudo git clone https://github.com/cytopia/nixos-config /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --dir /etc/nixos/hosts/shell

- delete configration.nix
- comment out all fileSystems."/" stuff
- comment out swapDevices stuff

cd /mnt/etc/nixos
git add hardware-configuration.nix
sudo nixos-install --flake .#shell

# Set password
sudo nixos-enter --root /mnt -c "passwd cytopia"
```
