#!/usr/bin/env bash
# Idempotent toolchain and dependency install for a Cursor cloud agent.
#
# Cloud Agent VMs boot with tini, not systemd, so a machine without Nix gets
# the pinned single-user install. A snapshot that already has the multi-user
# daemon just starts that daemon. Nix and devenv are linked into /usr/local/bin,
# which is on the default PATH for both login and non-login shells.
# ~/.bashrc is not used: non-interactive shells skip it.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

toolchain_bin=/usr/local/lib/verily-toolchain/bin
nix_version=2.35.5
devenv_cache=https://devenv.cachix.org
devenv_cache_key='devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw='

log() {
  printf 'cloud-install: %s\n' "$*"
}

# Add a space-separated value to a nix.conf key. A second run leaves the file
# unchanged. Uses sudo when the file is not writable by this user.
nix_conf_add() {
  local file="$1" key="$2" value="$3"
  local use_sudo=0 tmp
  # Files under $HOME belong to this user. sudo would create a root-owned
  # config that later Nix invocations cannot read.
  if [[ "$file" == "$HOME/"* ]]; then
    mkdir -p "$(dirname "$file")"
  elif [ -e "$file" ] && [ ! -w "$file" ]; then
    use_sudo=1
  elif [ ! -e "$file" ] && [ ! -w "$(dirname "$file")" ]; then
    use_sudo=1
  fi
  tmp="$(mktemp)"
  if [ -f "$file" ]; then
    if [ "$use_sudo" -eq 1 ]; then
      sudo -n cat "$file" >"$tmp"
    else
      cat "$file" >"$tmp"
    fi
  fi
  if grep -Eq "^${key} =" "$tmp" && grep -E "^${key} =" "$tmp" | grep -Fq -- "$value"; then
    rm -f "$tmp"
    return 0
  fi
  if grep -Eq "^${key} =" "$tmp"; then
    awk -v key="$key" -v value="$value" '
      $0 ~ "^" key " =" {
        if (!done) {
          print $0 " " value
          done = 1
        }
        next
      }
      { print }
    ' "$tmp" >"${tmp}.new"
    mv "${tmp}.new" "$tmp"
  else
    printf '%s = %s\n' "$key" "$value" >>"$tmp"
  fi
  if [ "$use_sudo" -eq 1 ]; then
    sudo -n mkdir -p "$(dirname "$file")"
    sudo -n cp "$tmp" "$file"
  else
    mkdir -p "$(dirname "$file")"
    cp "$tmp" "$file"
  fi
  rm -f "$tmp"
}

ensure_flakes() {
  local features
  features="$(nix config show experimental-features 2>/dev/null || true)"
  if [[ "$features" == *nix-command* && "$features" == *flakes* ]]; then
    log "nix-command and flakes are enabled"
    return 0
  fi
  local file="$HOME/.config/nix/nix.conf"
  nix_conf_add "$file" experimental-features nix-command
  nix_conf_add "$file" experimental-features flakes
  log "enabled nix-command and flakes"
}

ensure_binary_caches() {
  # One file only. Writing the same extra-substituter into both the system
  # and user configs makes Nix list the cache twice and warn on every build.
  local file="$HOME/.config/nix/nix.conf"
  if [ -f /etc/nix/nix.conf ]; then
    file=/etc/nix/nix.conf
  fi
  nix_conf_add "$file" extra-substituters "$devenv_cache"
  nix_conf_add "$file" extra-trusted-public-keys "$devenv_cache_key"
  log "substituters: $(nix config show substituters 2>/dev/null || true)"
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
  # Nix's wrapper lives on the default PATH (/usr/local/bin) and, for login
  # shells, ahead of it. Do not prepend the toolchain directory: a login
  # shell inside `devenv shell` would then pick a stale rustc over the one
  # devenv just put on PATH.
  sudo -n rm -f /etc/profile.d/zz-verily-toolchain.sh
  sudo -n tee /etc/profile.d/zz-verily-nix.sh >/dev/null <<'EOF'
if [ -d /usr/local/lib/verily-nix/bin ]; then
  PATH="/usr/local/lib/verily-nix/bin:${PATH}"
  export PATH
fi
EOF
  if [ -f "$HOME/.profile" ] && grep -q 'verily-toolchain' "$HOME/.profile"; then
    python3 - "$HOME/.profile" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
start = text.find("# verily-toolchain:")
if start == -1:
    raise SystemExit(0)
end = text.find("\nfi\n", start)
if end == -1:
    raise SystemExit("verily-toolchain block in ~/.profile is not closed")
path.write_text(text[:start] + text[end + 4 :])
PY
  fi
  export PATH="/usr/local/lib/verily-nix/bin:${PATH}"
}

ensure_devenv() {
  if ! command -v devenv >/dev/null 2>&1; then
    log "installing devenv from nixpkgs"
    nix profile install nixpkgs#devenv
    hash -r
  fi
  local src
  src="$(readlink -f "$(command -v devenv)")"
  sudo -n mkdir -p "$toolchain_bin"
  sudo -n ln -sfn "$src" /usr/local/bin/devenv
  sudo -n ln -sfn "$src" "$toolchain_bin/devenv"
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
ensure_binary_caches
ensure_profile_path
ensure_devenv
log "warming devenv shell"
devenv shell -- true
link_devenv_tools
ensure_flutter
log "installing Dart, Flutter, and Codama dependencies"
devenv shell install:all
log "fetching Rust crates"
devenv shell -- cargo fetch --locked
devenv shell -- cargo fetch --locked --manifest-path programs/verily_escrow/tests/mollusk/Cargo.toml
devenv shell -- cargo fetch --locked --manifest-path verily_kit/Cargo.toml
ensure_lk
log "building the Linux kit host"
devenv shell -- bash -c 'cd verily_kit && lk native prepare linux'
# prepare rewrites generated host modules with its own wrapping. The
# committed copies are rustfmt's, so put those paths back.
git checkout -- \
  verily_kit/android/src/lib.rs \
  verily_kit/ios/src/lib.rs \
  verily_kit/linux/src/lib.rs \
  verily_kit/linux/src/main.rs \
  verily_kit/macos/src/lib.rs \
  verily_kit/windows/src/lib.rs \
  verily_kit/windows/src/main.rs \
  verily_kit/verily_app/src/routes.rs
log "done"
