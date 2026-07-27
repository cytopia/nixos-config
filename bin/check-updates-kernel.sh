#!/usr/bin/env bash

NIXOS_RELEASE="nixos-26.05"


nixos_get_default_kernel_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/os-specific/linux/kernel/kernels-org.json" \
    | jq -r 'del(.testing) | .[] | select(.lts == true) | .version' \
    | grep '6\.18'
}
nixos_get_7_0_kernel_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/os-specific/linux/kernel/kernels-org.json" \
    | jq -r 'del(.testing) | .[] | select(.lts == false) | .version' \
    | grep '7\.0'
}
nixos_get_latest_kernel_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/os-specific/linux/kernel/kernels-org.json" \
    | jq -r 'del(.testing) | .[] | select(.lts == false) | .version' \
    | sort -V \
    | tail -1
}
nixos_get_zen_kernel_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/os-specific/linux/kernel/zen-kernels.nix" \
    | grep -E 'version\s*=\s*".+";' \
    | awk -F '"' '{print $2}'
}
nixos_get_xanmod_kernel_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/os-specific/linux/kernel/xanmod-kernels.nix" \
    | grep -E 'version\s*=\s*".+";' \
    | awk -F '"' '{print $2}' \
    | sort -urV \
    | head -1
}

channel_age() {
  local branch=$1 json ts now age
  [ -z "$branch" ] && { echo "usage: channel-age <branch>" >&2; return 2; }

  json=$(curl -fsSL "https://prometheus.nixos.org/api/v1/query?query=channel_update_time")
  json=${json//[$' \t\r\n']/}

  [[ $json =~ \"channel\":\"${branch//./\\.}\"[^[]*\[[0-9.]+,\"([0-9]+)\" ]] \
    || { echo "channel '$branch' not found" >&2; return 1; }
  ts=${BASH_REMATCH[1]}

  now=$(date +%s); age=$(( now - ts ))

  if   (( age > 86400 )); then            # > 1 day  -> nearest day, drop h/m
    printf '%2d days  ago\n' $(( (age + 43200) / 86400 ))
  elif (( age > 3600 ));  then            # > 1 hour -> nearest hour, drop m
    printf '%2d hours ago\n' $(( (age + 1800) / 3600 ))
  else                                    # otherwise -> minutes
    printf '%2d min   ago\n' $(( (age + 30) / 60 ))
  fi
}

TIME_NIXPKGS="$( channel_age "nixpkgs-unstable" )"
TIME_NIXOS="$( channel_age "nixos-unstable" )"
TIME_RELEASE="$( channel_age "nixos-26.05" )"


echo
echo "###################################################################################"
echo "###################################################################################"

echo
echo "==== KERNEL.ORG ===="
curl -sS https://kernel.org/ | grep -Eo 'linux-.+\.tar\.[gx]z' | sort -Vur | sed 's/\.tar.*//g'

echo
echo "==== NixOS default Kernel ===="
echo "STAGING: $( nixos_get_default_kernel_version "staging-nixos" )"
echo "MASTER:  $( nixos_get_default_kernel_version "master" )"
echo "NIXPKGS: $( nixos_get_default_kernel_version "nixpkgs-unstable" )  [${TIME_NIXPKGS}]"
echo "NIXOS:   $( nixos_get_default_kernel_version "nixos-unstable" )  [${TIME_NIXOS}] (my branch)"
echo "26.05:   $( nixos_get_default_kernel_version "${NIXOS_RELEASE}" )  [${TIME_RELEASE}]"

#echo
#echo "==== NixOS 7.0 Kernel ===="
#echo "STAGING: $( nixos_get_7_0_kernel_version "staging-nixos" )"
#echo "MASTER:  $( nixos_get_7_0_kernel_version "master" )"
#echo "NIXPKGS: $( nixos_get_7_0_kernel_version "nixpkgs-unstable" )  [${TIME_NIXPKGS}]"
#echo "NIXOS:   $( nixos_get_7_0_kernel_version "nixos-unstable" )  [${TIME_NIXOS}] (my branch)"
#echo "26.05:   $( nixos_get_7_0_kernel_version "${NIXOS_RELEASE}" )  [${TIME_RELEASE}]"

echo
echo "==== NixOS latest Kernel ===="
echo "STAGING: $( nixos_get_latest_kernel_version "staging-nixos" )"
echo "MASTER:  $( nixos_get_latest_kernel_version "master" )"
echo "NIXPKGS: $( nixos_get_latest_kernel_version "nixpkgs-unstable" )  [${TIME_NIXPKGS}]"
echo "NIXOS:   $( nixos_get_latest_kernel_version "nixos-unstable" )  [${TIME_NIXOS}] (my branch)"
echo "26.05:   $( nixos_get_latest_kernel_version "${NIXOS_RELEASE}" )  [${TIME_RELEASE}]"

echo
echo "==== NixOS Zen Kernel ===="
echo "STAGING: $( nixos_get_zen_kernel_version "staging-nixos" )"
echo "MASTER:  $( nixos_get_zen_kernel_version "master" )"
echo "NIXPKGS: $( nixos_get_zen_kernel_version "nixpkgs-unstable" )"
echo "NIXOS:   $( nixos_get_zen_kernel_version "nixos-unstable" ) (my branch)"
echo "26.05:   $( nixos_get_zen_kernel_version "${NIXOS_RELEASE}" )"

echo
echo "==== NixOS XanMod Kernel ===="
echo "STAGING: $( nixos_get_xanmod_kernel_version "staging-nixos" )"
echo "MASTER:  $( nixos_get_xanmod_kernel_version "master" )"
echo "NIXPKGS: $( nixos_get_xanmod_kernel_version "nixpkgs-unstable" )"
echo "NIXOS:   $( nixos_get_xanmod_kernel_version "nixos-unstable" ) (my branch)"
echo "26.05:   $( nixos_get_xanmod_kernel_version "${NIXOS_RELEASE}" )"
