#!/bin/sh

# How to run this script as root:
# nix-shell -p curl --run "curl -sSL https://raw.githubusercontent.com/cytopia/nixos-config/main/bootstrap.sh" | bash

set -e
set -u


# The system user to use
MY_USER="cytopia"

REPO_LINK="https://github.com/cytopia/nixos-config"
REPO_PATH="/home/${MY_USER}/.config/nixos-config"

# The default nixos custom config within above specified repository
# that must be included in /etc/nixos/configuration.nix
MY_CONFIG="${REPO_PATH}/default.nix"


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

###
### 2. Check if user exists
###
if ! getent passwd "${MY_USER}" > /dev/null 2>&1; then
	echo "ERROR: User does not exist: ${MY_USER}"
	exit 1
fi

###
### 3. Check if home directory exist
###
if [ ! -e "/home/${MY_USER}" ]; then
	echo "ERROR: Home directory does not exist: /home/${MY_USER}"
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
