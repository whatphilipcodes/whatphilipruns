#!/usr/bin/env bash
# Runs ON THE SERVER as the admin user: `cd scripts && bash remote-setup.sh`.
# Self-contained on purpose (no lib.sh): makes this repo the system config so that a plain
# `sudo nixos-rebuild switch|dry-activate` works without --flake.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$REPO"

# Flakes in a git repo only see tracked files, and flake.lock was created untracked on the
# provisioning machine: stage everything so the lock (and any new files) are honoured.
if [ -d .git ]; then
  if command -v git > /dev/null; then
    git add -A
  else
    nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c git add -A
  fi
fi

if sudo -n true 2> /dev/null; then
  sudo rm -rf /etc/nixos
  sudo ln -s "$REPO" /etc/nixos
  echo "/etc/nixos -> $REPO"
else
  echo "warning: passwordless sudo not available, run this yourself:" >&2
  echo "  sudo rm -rf /etc/nixos && sudo ln -s $REPO /etc/nixos" >&2
fi