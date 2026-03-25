#!/bin/bash

set -eu
set -o pipefail

MY_SRC="$(cd -P -- "$(dirname -- "${0}")" && pwd -P)"
MY_DST="${HOME}/.config"

symlink() {
  src="${1}"
  dst="${2}"

  if [ ! -f "${src}" ] && [ ! -d "${src}" ]; then
    echo "Error: source file does not exist: ${src}"
    return 1
  fi

  # 2) Check if the new target file already exists
  #    ordinary file (-f)
  #    symlink (-h)
  #    directory (-d)
  if [ -f "${dst}" ] || [ -h "${dst}" ] || [ -d "${dst}" ]; then
    echo "rm -rf ${dst}"
    rm -rf "${dst}"
  fi

  # 3) Symlink
  echo "ln -s ${src} ${dst}"
  ln -s "${src}" "${dst}"
}

symlink "${MY_SRC}/foot" "${MY_DST}/foot"
symlink "${MY_SRC}/tmux" "${MY_DST}/tmux"
symlink "${MY_SRC}/fuzzel" "${MY_DST}/fuzzel"
symlink "${MY_SRC}/sway" "${MY_DST}/sway"
symlink "${MY_SRC}/swayimg" "${MY_DST}/swayimg"
symlink "${MY_SRC}/mako" "${MY_DST}/mako"
symlink "${MY_SRC}/direnv" "${MY_DST}/direnv"
symlink "${MY_SRC}/ironbar" "${MY_DST}/ironbar"
symlink "${MY_SRC}/i3status-rust" "${MY_DST}/i3status-rust"
symlink "${MY_SRC}/starship.toml" "${MY_DST}/starship.toml"
