#!/bin/sh

# Not yet finished and working
exit 1


# How to run this script as root:
# nix-shell -p curl --run \
#   "curl -sSL https://raw.githubusercontent.com/cytopia/nixos-config/main/bootstrap.sh" \
#   | bash -s -- my_custom_host my_custom_user

set -e
set -u

# Assign variables from command line arguments (fails if not provided)
MY_HOST="${1:?ERROR: You must provide a hostname as the second argument}"
MY_USER="${2:?ERROR: You must provide a username as the first argument}"


# The system user to use
REPO_LINK="https://github.com/cytopia/nixos-config"
REPO_PATH="/home/${MY_USER}/.config/nixos-config"



####################################################################################################
#
# Pre-flight checks
#
####################################################################################################

###
### 1. Check if we are root
###
if [ "$(id -u)" -ne "0" ]; then
	echo "ERROR: This script must be run as root"
	exit 1
fi


####################################################################################################
#
# Pre-flight checks
#
####################################################################################################

###
### 1. Clone git repository if it does not exist
###
mkdir -p "$(dirname "${REPO_PATH}" )" || true
chown "${MY_USER}:users" "$(dirname "${REPO_PATH}")"
if [ ! -e "${REPO_PATH}" ]; then
	nix-shell -p git --run "git clone ${REPO_LINK} ${REPO_PATH}"
	chown -R ${MY_USER}:users ${REPO_PATH}
fi

###
### 2. Verify files in git directory
###
if [ ! -e "${MY_CONFIG}" ]; then
	echo "ERROR: Default custom NixOS config not found: ${MY_CONFIG}"
	exit 1
fi


####################################################################################################
#
# Inject custom config
#
####################################################################################################

###
### 1. Inject config into /etc/nixos/configuration.nix
###
nix-shell -p perl --run 'perl -0777 -i -pe "s|imports\s*=\s*\[.*?\./hardware-configuration\.nix.*?\];|imports =\n    [\n      ./hardware-configuration.nix\n      '"$MY_CONFIG"'\n    ];|gs" /etc/nixos/configuration.nix'
