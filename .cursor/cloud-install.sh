#!/usr/bin/env bash
# Idempotent toolchain and dependency install for a Cursor cloud agent.
#
# Cloud Agent VMs boot with tini, not systemd, so a machine without Nix gets
# the pinned single-user install. A snapshot that already has the multi-user
# daemon just starts that daemon. Tools are linked onto a directory that
# login shells (bash -l) prepend, because ~/.bashrc is skipped when the shell
# is not interactive.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

toolchain_bin=/usr/local/lib/verily-toolchain/bin
nix_version=2.35.5
devenv_ref=github:cachix/devenv/v2.4.0

log() {
  printf 'cloud-install: %s\n' "$*"
}

ensure_flakes() {
  if [ -f /etc/nix/nix.conf ] && grep -q 'flakes' /etc/nix/nix.conf; then
    return 0
  fi
  mkdir -p "$HOME/.config/nix"
  local conf="$HOME/.config/nix/nix.conf"
  if [ ! -f "$conf" ] || ! grep -q 'experimental-features' "$conf"; then
    printf 'experimental-features = nix-command flakes\n' >>"$conf"
  fi
}

start_nix_daemon() {
  local sock=/nix/var/nix/daemon-socket/socket
  local nix_bin=/nix/var/nix/profiles/default/bin/nix
  local daemon_bin=/nix/var/nix/profiles/default/bin/nix-daemon
  if [ ! -x "$daemon_bin" ]; then
    return 0
  fi
  if [ -S "$sock" ] && "$nix_bin" store info >/dev/null 2>&1; then
    log "nix-daemon is already running"
    return 0
  fi
  sudo -n rm -f "$sock"
  sudo -n mkdir -p /nix/var/nix/daemon-socket
  sudo -n sh -c "setsid '$daemon_bin' >/tmp/nix-daemon.log 2>&1 < /dev/null &"
  local _
  for _ in $(seq 1 50); do
    if "$nix_bin" store info >/dev/null 2>&1; then
      log "nix-daemon is ready"
      return 0
    fi
    sleep 0.2
  done
  echo "nix-daemon did not become ready" >&2
  tail -n 40 /tmp/nix-daemon.log >&2 || true
  exit 1
}

install_nix() {
  if [ -x /nix/var/nix/profiles/default/bin/nix ] || [ -x "$HOME/.nix-profile/bin/nix" ]; then
    return 0
  fi
  log "installing single-user Nix $nix_version"
  curl --fail --location --silent --show-error \
    "https://releases.nixos.org/nix/nix-${nix_version}/install" |
    sh -s -- --no-daemon --yes --no-modify-profile --no-channel-add
}

ensure_nix_on_path() {
  start_nix_daemon
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
  if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    sudo -n mkdir -p /usr/local/lib/verily-nix/bin
    # Keep the wrapper that starts the daemon when a login shell calls nix
    # before cloud-start.sh has finished.
    if [ ! -x /usr/local/lib/verily-nix/bin/nix ]; then
      sudo -n tee /usr/local/lib/verily-nix/bin/nix >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
real=/nix/var/nix/profiles/default/bin/nix
daemon=/nix/var/nix/profiles/default/bin/nix-daemon
sock=/nix/var/nix/daemon-socket/socket
if "$real" store info >/dev/null 2>&1; then
  exec "$real" "$@"
fi
if ! pgrep -x nix-daemon >/dev/null 2>&1; then
  sudo rm -f "$sock"
  sudo mkdir -p /nix/var/nix/daemon-socket
  sudo sh -c "setsid '$daemon' >/tmp/nix-daemon.log 2>&1 < /dev/null &"
fi
for _ in $(seq 1 50); do
  if "$real" store info >/dev/null 2>&1; then
    exec "$real" "$@"
  fi
  sleep 0.2
done
echo "nix-daemon did not become ready" >&2
exit 1
EOF
      sudo -n chmod 755 /usr/local/lib/verily-nix/bin/nix
    fi
    sudo -n ln -sfn /usr/local/lib/verily-nix/bin/nix /usr/local/bin/nix
  elif [ -x "$HOME/.nix-profile/bin/nix" ]; then
    sudo -n ln -sfn "$HOME/.nix-profile/bin/nix" /usr/local/bin/nix
  fi
  hash -r
  command -v nix >/dev/null 2>&1
}

ensure_profile_path() {
  sudo -n tee /etc/profile.d/zz-verily-toolchain.sh >/dev/null <<EOF
if [ -d ${toolchain_bin} ]; then
  PATH="${toolchain_bin}:\${PATH}"
  export PATH
fi
EOF
  sudo -n tee /etc/profile.d/zz-verily-nix.sh >/dev/null <<'EOF'
if [ -d /usr/local/lib/verily-nix/bin ]; then
  PATH="/usr/local/lib/verily-nix/bin:${PATH}"
  export PATH
fi
EOF
  export PATH="${toolchain_bin}:/usr/local/lib/verily-nix/bin:${PATH}"
}

ensure_devenv() {
  if command -v devenv >/dev/null 2>&1; then
    return 0
  fi
  log "installing devenv 2.4.0"
  nix profile install --accept-flake-config "$devenv_ref"
  hash -r
}

link_devenv_tools() {
  sudo -n mkdir -p "$toolchain_bin"
  local listing tool src
  listing="$(devenv shell -- bash -c 'for tool in rustc cargo rustfmt rust-analyzer cargo-clippy pina serverpod fvm dprint nixfmt ktlint gitleaks; do
    command -v "$tool"
  done' 2>/dev/null)"
  while IFS= read -r src; do
    [[ "$src" == /* ]] || continue
    tool="$(basename "$src")"
    sudo -n ln -sfn "$src" "$toolchain_bin/$tool"
    sudo -n ln -sfn "$src" "/usr/local/bin/$tool"
  done <<<"$listing"
  if [ -x "$HOME/.nix-profile/bin/devenv" ]; then
    sudo -n ln -sfn "$HOME/.nix-profile/bin/devenv" /usr/local/bin/devenv
    sudo -n ln -sfn "$HOME/.nix-profile/bin/devenv" "$toolchain_bin/devenv"
  fi
}

ensure_flutter() {
  local flutter_version cached
  flutter_version="$(awk -F'"' '/"flutter"/ { print $4; exit }' .fvmrc)"
  if ! [[ "$flutter_version" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "The Flutter version in .fvmrc is missing or invalid." >&2
    exit 1
  fi
  cached="${FVM_CACHE_PATH:-$HOME/fvm}/versions/$flutter_version"
  if [ ! -x "$cached/bin/flutter" ]; then
    log "installing Flutter $flutter_version"
    devenv shell -- fvm install "$flutter_version"
  fi
  sudo -n ln -sfn "$cached/bin/flutter" "$toolchain_bin/flutter"
  sudo -n ln -sfn "$cached/bin/dart" "$toolchain_bin/dart"
  sudo -n ln -sfn "$cached/bin/flutter" /usr/local/bin/flutter
  sudo -n ln -sfn "$cached/bin/dart" /usr/local/bin/dart
}

ensure_lk() {
  local rev stamp
  rev="$(awk -F'"' '/github.com\/ifiokjr\/leptoskit/ { print $4; exit }' verily_kit/Cargo.toml)"
  if ! [[ "$rev" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Could not read the leptoskit rev from verily_kit/Cargo.toml." >&2
    exit 1
  fi
  sudo -n mkdir -p /usr/local/lib/verily-lk
  stamp=/usr/local/lib/verily-lk/REV
  if [ -x /usr/local/bin/lk ] && [ ! -f "$stamp" ]; then
    printf '%s\n' "$rev" | sudo -n tee "$stamp" >/dev/null
  fi
  if [ -x /usr/local/bin/lk ] && [ "$(cat "$stamp" 2>/dev/null || true)" = "$rev" ]; then
    log "lk $rev is already installed"
    return 0
  fi
  log "installing leptoskit_cli $rev"
  devenv shell -- cargo install --git https://github.com/ifiokjr/leptoskit \
    --rev "$rev" leptoskit_cli --locked --root /usr/local/lib/verily-lk --force
  sudo -n ln -sfn /usr/local/lib/verily-lk/bin/lk /usr/local/bin/lk
  sudo -n ln -sfn /usr/local/lib/verily-lk/bin/leptoskit /usr/local/bin/leptoskit
  sudo -n ln -sfn /usr/local/lib/verily-lk/bin/lk "$toolchain_bin/lk"
  sudo -n ln -sfn /usr/local/lib/verily-lk/bin/leptoskit "$toolchain_bin/leptoskit"
  printf '%s\n' "$rev" | sudo -n tee "$stamp" >/dev/null
}

install_nix
ensure_nix_on_path
ensure_flakes
ensure_profile_path
ensure_devenv
link_devenv_tools
ensure_flutter
log "installing Dart, Flutter, and Codama dependencies"
devenv shell install:all
log "fetching Rust crates"
devenv shell -- cargo fetch --locked
devenv shell -- cargo fetch --locked --manifest-path programs/verily_escrow/tests/mollusk/Cargo.toml
devenv shell -- cargo fetch --locked --manifest-path verily_kit/Cargo.toml
ensure_lk
log "done"
