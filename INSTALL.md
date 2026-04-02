# Install


Regardless of the option to choose, you require a working internet connection.
```bash
# or use graphical install to connect to WiFi
nmcli device wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

## Option A (one cmd)

```bash
curl -sSL https://raw.githubusercontent.com/cytopia/nixos-config/main/bootstrap.sh \
  | bash -s -- <MY_HOSTNAME> <MY_USERNAME>
```

## Option B (manually)

### Format Disk
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:cytopia/nixos-config#<HOSTNAME>
```

### Install NixOS system
```bash
# Install System
sudo mkdir -p /mnt/etc/nixos
sudo nix-shell -p git --run "git clone https://github.com/cytopia/nixos-config /mnt/etc/nixos"
sudo nixos-install --option experimental-features "nix-command flakes" --flake /mnt/etc/nixos#<HOSTNAME>

# Set password
sudo nixos-enter --root /mnt -c "passwd cytopia"
```

### Install Home-Manager
```bash
# Fix permissions for your flake repository
sudo nixos-enter --root /mnt -c "chown -R cytopia:users /etc/nixos"

# Run Home Manager as your user inside the chroot
# NOTE: This will error, as home-manager wants to start services that don't exist in a chroot env.
sudo nixos-enter --root /mnt -c "su - cytopia -c 'nix --experimental-features \"nix-command flakes\" run github:nix-community/home-manager -- switch --flake /etc/nixos#cytopia'"
```
