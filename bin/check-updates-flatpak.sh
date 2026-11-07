#!/usr/bin/env bash

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIX_FLATPAK_REPO="https://github.com/gmodena/nix-flatpak"

nix_flatpak_get_pinned_tag() {
  grep -E 'nix-flatpak\.url' "${FLAKE_DIR}/flake.nix" \
    | sed -E 's|.*refs/tags/([^"?]+).*|\1|'
}
nix_flatpak_get_locked_rev() {
  jq -r '.nodes["nix-flatpak"].locked.rev' "${FLAKE_DIR}/flake.lock"
}
nix_flatpak_get_remote_tags() {
  # Peeled ^{} lines are kept: they carry the commit of annotated tags.
  git ls-remote --tags "${NIX_FLATPAK_REPO}"
}
nix_flatpak_get_latest_tag() {
  local remote_tags="${1}"
  printf '%s\n' "${remote_tags}" \
    | awk '{print $2}' \
    | sed -e 's|^refs/tags/||' -e 's|\^{}$||' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -uV \
    | tail -1
}
nix_flatpak_get_tag_commit() {
  local remote_tags="${1}" tag="${2}" commit
  commit="$( printf '%s\n' "${remote_tags}" | awk -v r="refs/tags/${tag}^{}" '$2 == r {print $1}' )"
  [ -z "${commit}" ] && commit="$( printf '%s\n' "${remote_tags}" | awk -v r="refs/tags/${tag}" '$2 == r {print $1}' )"
  echo "${commit}"
}

PINNED_TAG="$( nix_flatpak_get_pinned_tag )"
LOCKED_REV="$( nix_flatpak_get_locked_rev )"
REMOTE_TAGS="$( nix_flatpak_get_remote_tags 2>/dev/null )"
LATEST_TAG="$( nix_flatpak_get_latest_tag "${REMOTE_TAGS}" )"


echo
echo "###################################################################################"
echo "###################################################################################"

echo
echo "==== nix-flatpak (flake input) ===="
echo "PINNED:  ${PINNED_TAG}  (locked rev ${LOCKED_REV:0:7})"
if [ -z "${LATEST_TAG}" ]; then
  echo "LATEST:  unknown (cannot reach github.com)"
else
  echo "LATEST:  ${LATEST_TAG}"
  if [ "${LATEST_TAG}" = "${PINNED_TAG}" ]; then
    echo "STATUS:  up to date"
  else
    echo "STATUS:  UPDATE AVAILABLE"
    echo "         1. edit flake.nix: nix-flatpak.url = \"github:gmodena/nix-flatpak/?ref=refs/tags/${LATEST_TAG}\";"
    echo "         2. nix flake update nix-flatpak"
    echo "         3. read the release notes"
    echo "         4. sudo nixos-rebuild switch --flake .#\$(hostname)"
  fi
  echo "NOTES:   ${NIX_FLATPAK_REPO}/releases/tag/${LATEST_TAG}"

  PINNED_COMMIT="$( nix_flatpak_get_tag_commit "${REMOTE_TAGS}" "${PINNED_TAG}" )"
  if [ -n "${PINNED_COMMIT}" ] && [ "${PINNED_COMMIT}" != "${LOCKED_REV}" ]; then
    echo "WARNING: flake.lock rev ${LOCKED_REV:0:7} differs from tag ${PINNED_TAG} commit ${PINNED_COMMIT:0:7} (lock out of sync with pinned tag)"
    echo "         fix: nix flake update nix-flatpak"
  fi
fi

echo
echo "==== Flatpak updates pending (system installation) ===="
if ! command -v flatpak >/dev/null 2>&1; then
  echo "flatpak not installed on this machine"
else
  PENDING="$( flatpak remote-ls --system --updates --columns=application,version,branch,origin 2>&1 )"
  echo "${PENDING:-none}"
  echo "APPLY:   sudo flatpak update"
fi
