# Install

The whole repository ends up in `/home/cytopia/.config/nixos-conf` (owned by
`cytopia:users`) and the system is installed from that flake.

Regardless of the option to choose, you require a working internet connection.
```bash
# or use graphical install to connect to WiFi
nmcli device wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

## Option A (one cmd)

```bash
curl -sSL https://raw.githubusercontent.com/cytopia/nixos-config/main/bootstrap.sh \
  | bash -s -- <MY_HOSTNAME>
```

## Option B (manually)

### Format Disk
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake github:cytopia/nixos-config#<HOSTNAME>
# disko asks you to type 'yes' before wiping (skip with --yes-wipe-all-disks),
# then cryptsetup asks for the DISK ENCRYPTION (LUKS) passphrase.
```

### Install NixOS system
```bash
# Clone the repo to its final place: cytopia's ~/.config/nixos-conf.
# The home directory does not exist yet (the user is created by the install);
# ownership is fixed after nixos-install below.
sudo mkdir -p /mnt/home/cytopia/.config
sudo nix-shell -p git --run "git clone https://github.com/cytopia/nixos-config /mnt/home/cytopia/.config/nixos-conf"

# Regenerate hardware-configuration.nix for THIS machine.
# disko already defines filesystems and swap, so exclude them with --no-filesystems.
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
  | sudo tee /mnt/home/cytopia/.config/nixos-conf/hosts/machines/<HOSTNAME>/hardware-configuration.nix >/dev/null

# Install from the flake in cytopia's home
sudo nixos-install --option experimental-features "nix-command flakes" \
  --flake /mnt/home/cytopia/.config/nixos-conf#<HOSTNAME>
# (nixos-install asks for the ROOT password at the end of the install)

# Set the cytopia login password
sudo nixos-enter --root /mnt -c "passwd cytopia"

# Make the home directory and the repo belong to cytopia:users
sudo nixos-enter --root /mnt -c "chown -R cytopia:users /home/cytopia && chmod 0700 /home/cytopia"
```

### Install Home-Manager
```bash
# Run Home Manager as your user inside the chroot
sudo nixos-enter --root /mnt
# (inside chroot) start the daemon so a non-root user gets store access:
nix-daemon >/tmp/nix-daemon.log 2>&1 &
su - cytopia -c 'home-manager switch --flake /home/cytopia/.config/nixos-conf#cytopia@<HOSTNAME>'
# NOTE: activation may complain about systemd user services (no user session in a
# chroot). The generation is built anyway; services start at first login.
```

### Install dotfiles
```bash
# (still inside the chroot, after home-manager) symlink dotfiles/* into ~/.config as cytopia.
# It replaces (rm -rf) any existing ~/.config/<name> it manages.
su - cytopia -c '/home/cytopia/.config/nixos-conf/dotfiles/install.sh'
exit
```
