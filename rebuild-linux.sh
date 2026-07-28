#!/usr/bin/env bash
# Rebuild the home-manager config after editing anything in this repo.
# Usage: ./rebuild-linux.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Re-establish the symlink in case the repo moved.
ln -sfn "$DIR" ~/.dotfiles

# Source nix profile for PATH.
if [ -f /etc/profile.d/nix.sh ]; then
  # shellcheck disable=SC1091
  . /etc/profile.d/nix.sh
fi

exec home-manager switch --flake ~/.dotfiles#$(whoami)
