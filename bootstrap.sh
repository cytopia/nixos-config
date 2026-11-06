#!/usr/bin/env bash
#
# bootstrap.sh - one-shot NixOS install from the live installer ISO.
#
# Usage (from the booted NixOS installer, with internet):
#
#   curl -sSL https://raw.githubusercontent.com/cytopia/nixos-config/main/bootstrap.sh \
#     | bash -s -- <HOSTNAME>
#
# <HOSTNAME> must match a directory in hosts/machines/ (e.g. host, core, shell).
# The user is always "cytopia". The repo ends up in /home/cytopia/.config/nixos-conf
# (owned by cytopia:users) and the system is installed from there.
#
# What it does, in order:
#   1. sanity checks (UEFI, internet, hostname exists in the repo)
#   2. clone the repo
#   3. ask you to confirm, then DESTROY and partition the target disk with disko
#   4. put the repo at /mnt/home/cytopia/.config/nixos-conf (its final place)
#   5. generate hardware-configuration.nix for THIS machine (disko owns the filesystems)
#   6. nixos-install from that flake
#   7. set the root password
#   8. set the cytopia password
#   9. give /home/cytopia (and the repo) to cytopia:users
#  10. run home-manager inside the chroot (user services start at first login)
#  11. symlink the dotfiles (dotfiles/install.sh) into ~/.config as cytopia
#
# You will be asked for THREE different secrets, each announced by a banner:
#   - the DISK ENCRYPTION (LUKS) passphrase  - unlocks the disk at every boot
#   - the ROOT password
#   - the cytopia password                    - your login password
#
# After the first boot nothing is required; for future config changes:
#   sudo nixos-rebuild switch --flake ~/.config/nixos-conf#<HOSTNAME>
#   home-manager switch --flake ~/.config/nixos-conf#cytopia@<HOSTNAME>
#   ~/.config/nixos-conf/dotfiles/install.sh

set -euo pipefail

REPO="https://github.com/cytopia/nixos-config"
USER_NAME="cytopia"
USER_HOME="/home/$USER_NAME"
CONF_DIR="$USER_HOME/.config/nixos-conf"     # inside the installed system
HOST="${1:-}"

die() { echo "ERROR: $*" >&2; exit 1; }
banner() {
  echo
  echo "=================================================================="
  printf '  %s\n' "$@"
  echo "=================================================================="
  echo
}

[ -n "$HOST" ] || die "usage: bash -s -- <HOSTNAME>"

# This script is normally piped into bash, so stdin is the script itself.
# Do NOT 'exec </dev/tty' here: bash reads the script from stdin when piped,
# so that would make it read the REST OF THE SCRIPT from the terminal and
# hang silently with no output. Instead the whole body lives in main(), which
# bash parses completely before running, and only main's commands (read,
# cryptsetup, passwd) get /dev/tty as stdin - see the last line of this file.
main() {

NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

###
### 1. Sanity checks
###
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode (systemd-boot needs UEFI; disable CSM/legacy boot)"
curl -fsI https://github.com >/dev/null 2>&1 \
  || die "no internet. Connect first, e.g.: nmcli dev wifi connect \"SSID\" password \"PASSWORD\""

###
### 2. Clone the repo
###
WORK="$(mktemp -d)"
SRC="$WORK/nixos-config"
nix-shell -p git --run "git clone $REPO $SRC"
[ -f "$SRC/hosts/machines/$HOST/default.nix" ] \
  || die "unknown host '$HOST' (no hosts/machines/$HOST/ in the repo)"

###
### 3. Confirm, then wipe + partition + mount with disko
###
DISK="$(grep -oE 'device = "[^"]+"' "$SRC/hosts/machines/$HOST/disko-config.nix" | head -1 | cut -d'"' -f2 || true)"
banner "TARGET" \
       "host : $HOST" \
       "disk : ${DISK:-see disko-config.nix}"
[ -n "$DISK" ] && lsblk -dno NAME,SIZE,MODEL "$DISK" 2>/dev/null || true
echo
echo "!!! ALL DATA ON THIS DISK WILL BE DESTROYED !!!"
read -rp "Type the hostname ($HOST) to continue: " answer
[ "$answer" = "$HOST" ] || die "aborted"

banner "NEXT PROMPT: DISK ENCRYPTION (LUKS) PASSPHRASE" \
       "This passphrase unlocks the disk at every boot." \
       "cryptsetup will ask three times:" \
       "  'Enter passphrase'            -> choose it" \
       "  'Verify passphrase'           -> repeat it" \
       "  'Enter passphrase for /dev/…' -> repeat it once more (opens the disk)" \
       "(disko is downloaded first; the prompt may take a moment to appear)"

sudo nix "${NIX_FLAGS[@]}" run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake "$SRC#$HOST"

###
### 4. Put the repo at its final place inside the new system.
###    /home/cytopia does not exist yet (the user is created by the install);
###    ownership is fixed in step 9.
###
sudo mkdir -p "/mnt$USER_HOME/.config"
sudo cp -a "$SRC" "/mnt$CONF_DIR"

###
### 5. hardware-configuration.nix for THIS machine
###    The committed one was generated on different hardware. disko already
###    defines filesystems and swap, so exclude them with --no-filesystems.
###
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
  | sudo tee "/mnt$CONF_DIR/hosts/machines/$HOST/hardware-configuration.nix" >/dev/null

###
### 6. Install the system from the repo in cytopia's home
###    --no-root-passwd only suppresses nixos-install's own unlabeled root
###    password prompt at the end of the install; the root password is set
###    explicitly in step 7 so you can see which password you are typing.
###
banner "INSTALLING NixOS ($HOST) - this takes a while, no input needed"
sudo nixos-install \
  --no-root-passwd \
  --option experimental-features "nix-command flakes" \
  --flake "/mnt$CONF_DIR#$HOST"

###
### 7. Root password
###
banner "NEXT PROMPT: ROOT PASSWORD" \
       "Password for the 'root' account (not your login user)."
sudo nixos-enter --root /mnt -c "passwd root"

###
### 8. User password
###
banner "NEXT PROMPT: USER PASSWORD ($USER_NAME)" \
       "This is your login password. Also used for sudo."
sudo nixos-enter --root /mnt -c "passwd $USER_NAME"

###
### 9. Ownership: the home directory and the repo belong to cytopia:users
###    (done inside the chroot so the names resolve against the new system)
###
sudo nixos-enter --root /mnt -c "chown -R $USER_NAME:users $USER_HOME && chmod 0700 $USER_HOME"

###
### 10. home-manager (standalone) inside the chroot
###     There is no nix-daemon in the chroot, so start one, otherwise a
###     non-root user cannot access the Nix store. The activation may still
###     complain about systemd user services (no user session in a chroot);
###     the generation is built anyway and services start at first login.
###
banner "home-manager ($USER_NAME@$HOST) - no input needed"
sudo nixos-enter --root /mnt -c "
  nix-daemon >/dev/null 2>&1 &
  for i in \$(seq 1 50); do [ -S /nix/var/nix/daemon-socket/socket ] && break; sleep 0.1; done
  su - $USER_NAME -c 'home-manager switch --flake $CONF_DIR#$USER_NAME@$HOST'
" || echo "WARNING: home-manager reported errors (expected in a chroot). After first login run:
         home-manager switch --flake $CONF_DIR#$USER_NAME@$HOST"

###
### 11. Dotfiles: symlink dotfiles/* into ~/.config as cytopia.
###     It replaces (rm -rf) any existing ~/.config/<name> it manages.
###
banner "dotfiles -> ~/.config (as $USER_NAME) - no input needed"
sudo nixos-enter --root /mnt -c "su - $USER_NAME -c '$CONF_DIR/dotfiles/install.sh'"

banner "DONE" \
       "Repo: $CONF_DIR (owner $USER_NAME:users)" \
       "Remove the installer medium and reboot:  sudo reboot"

}

# Run everything with the terminal as stdin so prompts work under 'curl | bash'.
main "$@" </dev/tty
