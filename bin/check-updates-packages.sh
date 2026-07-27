#!/usr/bin/env bash

NIXOS_RELEASE="nixos-26.05"

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

nixos_get_sway_version() {
  local branch="${1}"
  curl -fsSL "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/${branch}/pkgs/by-name/sw/sway-unwrapped/package.nix" \
    | grep -E 'version\s*=\s*".+";' \
    | awk -F '"' '{print $2}' \
    | sort -urV \
    | head -1
}




TIME_NIXPKGS="$( channel_age "nixpkgs-unstable" )"
TIME_NIXOS="$( channel_age "nixos-unstable" )"
TIME_RELEASE="$( channel_age "nixos-26.05" )"


echo "###################################################################################"
echo "###################################################################################"

echo
echo "==== SWAY ===="
curl -sS https://github.com/swaywm/sway/releases \
  | grep -Eo '[^"]+/sway/tree/[^"]+' \
  | grep -Eo '[0-9]+\.[0-9]+.+' \
  | sed 's/-rc/~rc/' \
  | sort -Vur \
  | sed 's/~rc/-rc/'


echo
echo "==== NixOS Sway ===="
echo "STAGING: $( nixos_get_sway_version "staging-nixos" )"
echo "MASTER:  $( nixos_get_sway_version "master" )"
echo "NIXPKGS: $( nixos_get_sway_version "nixpkgs-unstable" )  [${TIME_NIXPKGS}]"
echo "NIXOS:   $( nixos_get_sway_version "nixos-unstable" )  [${TIME_NIXOS}] (my branch)"
echo "26.05:   $( nixos_get_sway_version "${NIXOS_RELEASE}" )  [${TIME_RELEASE}]"
