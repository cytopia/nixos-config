# Install


## Connect to the internet
```bash
# or use graphical install to connect to WiFi
nmcli device wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

## Format Disk
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:cytopia/nixos-config#shell
```

## Install NixOS system
```bash
# Install System
sudo mkdir -p /mnt/etc/nixos
sudo git clone https://github.com/cytopia/nixos-config /mnt/etc/nixos
cd /mnt/etc/nixos
sudo nixos-install --flake .#shell

# Set password
sudo nixos-enter --root /mnt -c "passwd cytopia"
```

## Install Home-Manager
```bash
# 1. Fix permissions for your flake repository
# You cloned the repo using `sudo`, so it's owned by root.
# Home Manager needs to read (and potentially create lock files in) this directory as your user.
sudo nixos-enter --root /mnt -c "chown -R cytopia:users /etc/nixos"

# 2. Run Home Manager as your user inside the chroot
# We use `su - cytopia` to ensure the $HOME environment variable is correctly set to /home/cytopia.
sudo nixos-enter --root /mnt -c "su - cytopia -c 'nix --experimental-features \"nix-command flakes\" run github:nix-community/home-manager -- switch --flake /etc/nixos#cytopia'"
```
