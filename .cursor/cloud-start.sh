#!/usr/bin/env bash
# Start the Nix daemon when this machine uses the multi-user install.
# Single-user Nix has no daemon. Installation belongs in cloud-install.sh;
# this only makes the daemon ready and stays attached so a dead daemon is
# visible as a non-zero start status.
set -euo pipefail

if [ -d /agent/repos/verily ]; then
  cd /agent/repos/verily
fi

sock=/nix/var/nix/daemon-socket/socket
nix_bin=/nix/var/nix/profiles/default/bin/nix
daemon_bin=/nix/var/nix/profiles/default/bin/nix-daemon

if [ ! -x "$daemon_bin" ]; then
  echo "nix has no multi-user daemon"
  exit 0
fi

if [ -S "$sock" ] && "$nix_bin" store info >/dev/null 2>&1; then
  echo "nix-daemon is already running"
  exit 0
fi

sudo -n rm -f "$sock"
sudo -n mkdir -p /nix/var/nix/daemon-socket
exec sudo -n "$daemon_bin"
