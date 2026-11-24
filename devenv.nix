{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  isCI = builtins.getEnv "CI" != "";
  extra = inputs.ifiokjr-nixpkgs.packages.${pkgs.stdenv.system};
  pinaPkgs = inputs.ifiokjr-nixpkgs-pina.packages.${pkgs.stdenv.system};
  # Pina lint drivers are tied to one rustc revision. Keep this aligned with
  # Pina 0.24.0's published driver so the security-lint lane stays reproducible.
  rustToolchain = pkgs.rust-bin.nightly."2026-09-15".default.override {
    # LeptosKit builds the browser/native guest and each phone host with
    # this same pinned compiler when invoked through devenv shell.
    targets = [
      "wasm32-unknown-unknown"
      "aarch64-apple-ios"
      "aarch64-apple-ios-sim"
      "aarch64-linux-android"
      "x86_64-linux-android"
    ];
    extensions = [
      "clippy"
      "llvm-tools-preview"
      "rust-analyzer"
      "rust-src"
      "rustc-dev"
      "rustfmt"
    ];
  };
  # Pina loads its rustc-linked lint driver by prepending the Rust sysroot to
  # the process-wide library path. On macOS, use the system compiler so SIP
  # strips that path before clang starts.
  pinaLintCc = if pkgs.stdenv.isDarwin then "/usr/bin/cc" else "${pkgs.stdenv.cc}/bin/cc";
  pinaLintCxx = if pkgs.stdenv.isDarwin then "/usr/bin/c++" else "${pkgs.stdenv.cc}/bin/c++";
  kitDir = "verily_kit";
  appId = "fun.verily.app";
  kitPort = "8184";
  sitePort = "8183";
  postgresPort = 8191;
  leptoskitRev = "4f52896af397cc38834ac9d937a04b02bc5c5bf4";
  devenvGitHook =
    name: script: arguments:
    pkgs.writeShellScript name ''
      set -euo pipefail
      project_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      cd "$project_root"
      export DEVENV_ROOT="$project_root"
      exec "${config.env.DEVENV_PROFILE}/bin/${script}" ${arguments} "$@"
    '';
  # Reads the port of this checkout's running Postgres from its pid file, so
  # several worktrees can each run a private database.
  resolvePostgresPort = ''
    postgres_pid_file="$DEVENV_ROOT/.devenv/state/postgres/postmaster.pid"
    postgres_port="''${PGPORT:-${toString postgresPort}}"
    if test -f "$postgres_pid_file"; then
      running_port="$(sed -n '4p' "$postgres_pid_file")"
      if [[ "$running_port" =~ ^[0-9]+$ ]]; then
        postgres_port="$running_port"
      fi
    fi
  '';
  onePasswordSandbox = ''
    op_config_dir="$DEVENV_ROOT/.devlogs/onepassword-cli"
    mkdir -p "$op_config_dir"
    chmod 700 "$op_config_dir"
    export OP_BIOMETRIC_UNLOCK_ENABLED=false
    export OP_CACHE=false
    export OP_CONFIG_DIR="$op_config_dir"
    export OP_LOAD_DESKTOP_APP_SETTINGS=false
  '';
in
{
  packages =
    with pkgs;
    [
      curl
      dprint
      ffmpeg
      gitleaks
      jq
      ktlint
      netcat
      nixfmt
      shfmt
      rustToolchain
      extra.agave
      pinaPkgs.pina
      extra.sbpf-linker
    ]
    ++ lib.optionals (!isCI) [
      pkgs._1password-cli
      pkgs.tmux
      extra.monosecret
    ]
    ++ lib.optionals stdenv.isDarwin [
      coreutils
      swift-format
      swiftlint
    ]
    # The kit's Linux host enables LeptosKit's gtk feature, so `lk lint`
    # builds glib-sys. pkg-config only sees packages in this shell.
    ++ lib.optionals stdenv.isLinux [
      gtk4
      pkg-config
    ];

  dotenv.disableHint = true;

  env = {
    SBF_TOOLS_VERSION = "v1.54";
  };

  # Rely on the global Apple SDK; the Nix Apple SDK conflicts with Xcode builds.
  apple.sdk = null;

  services = {
    postgres = {
      enable = !isCI;
      package = pkgs.postgresql_19;
      # PostGIS backs the geography columns and GiST indexes for action
      # places and location proof.
      extensions = exts: [ exts.postgis ];
      listen_addresses = "127.0.0.1";
      port = postgresPort;
      initialDatabases = [
        { name = "verily"; }
        { name = "verily_test"; }
      ];
      initialScript = ''
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
            CREATE ROLE postgres LOGIN SUPERUSER;
          ELSE
            ALTER ROLE postgres WITH SUPERUSER PASSWORD NULL;
          END IF;
        END
        $$;
        ALTER DATABASE verily OWNER TO postgres;
        ALTER DATABASE verily_test OWNER TO postgres;
      '';
    };
  };

  processes = {
    "server:up" = {
      exec = ''
        server:start
      '';
      process-compose.depends_on."devenv-up-postgres".condition = "process_healthy";
    };
  };

  git-hooks = lib.mkIf (!isCI) {
    package = pkgs.prek;
    hooks = {
      "secrets:commit" = {
        enable = true;
        name = "secrets:commit";
        description = "Scan staged changes for leaked secrets with gitleaks.";
        entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --verbose --redact --config .gitleaks.toml";
        pass_filenames = false;
        stages = [ "pre-commit" ];
      };
      format = {
        enable = true;
        name = "format";
        description = "Check formatting of staged files.";
        entry = "${devenvGitHook "verily-format-hook" "lint:format" ""}";
        pass_filenames = false;
        stages = [ "pre-commit" ];
      };
      "secrets:push" = {
        enable = true;
        name = "secrets:push";
        description = "Check git history for leaked secrets with gitleaks.";
        entry = "${pkgs.gitleaks}/bin/gitleaks detect --verbose --redact --config .gitleaks.toml";
        pass_filenames = false;
        stages = [ "pre-push" ];
      };
      "push:lint" = {
        enable = true;
        name = "push:lint";
        description = "Run the full lint suite before push.";
        entry = "${devenvGitHook "verily-push-lint-hook" "lint:all" ""}";
        pass_filenames = false;
        always_run = true;
        stages = [ "pre-push" ];
      };
      "push:test" = {
        enable = true;
        name = "push:test";
        description = "Run the test suite before push.";
        entry = "${devenvGitHook "verily-push-test-hook" "test:all" ""}";
        pass_filenames = false;
        always_run = true;
        stages = [ "pre-push" ];
      };
    };
  };

  scripts = {
    "server:start" = {
      exec = ''
        set -euo pipefail
        ${resolvePostgresPort}
        export DATABASE_URL="''${DATABASE_URL:-postgres://postgres@127.0.0.1:$postgres_port/verily}"
        export VERILY_PORT="''${VERILY_PORT:-${kitPort}}"
        ${onePasswordSandbox}
        cd "$DEVENV_ROOT/${kitDir}"
        exec monosecret run --profile default --reason "start Verily LeptosKit server" -- \
          ${rustToolchain}/bin/cargo run --bin verily-kit
      '';
      description = "Start the Verily LeptosKit server against local PostGIS.";
      binary = "bash";
    };
    "dev:kit" = {
      exec = ''
        set -euo pipefail
        if ! command -v lk >/dev/null 2>&1; then
          echo "lk is not on PATH. Install it from the pinned leptoskit rev:" >&2
          echo "  cargo install --git https://github.com/leptoskit/leptoskit --rev ${leptoskitRev} leptoskit_cli --locked" >&2
          exit 1
        fi
        ${resolvePostgresPort}
        export DATABASE_URL="''${DATABASE_URL:-postgres://postgres@127.0.0.1:$postgres_port/verily}"
        ${onePasswordSandbox}
        cd "$DEVENV_ROOT/${kitDir}"
        exec lk dev "$@"
      '';
      description = "Run the Verily LeptosKit development loop (web + server + live reload).";
      binary = "bash";
    };
    "secrets:check" = {
      exec = ''
        set -euo pipefail
        ${onePasswordSandbox}
        cd "$DEVENV_ROOT"
        monosecret check --profile development --reason "validate Verily development secrets"
        cd "$DEVENV_ROOT/${kitDir}"
        monosecret check --profile default --reason "validate verily_kit development secrets"
      '';
      description = "Validate the dotenv-first Monosecret development profiles without printing values.";
      binary = "bash";
    };
    "android:reverse" = {
      exec = ''
        set -euo pipefail
        device_id="''${SEEKER_DEVICE_ID:-SM02E4060324957}"
        if [ "$#" -gt 0 ]; then
          device_id="$1"
        fi
        adb -s "$device_id" get-state >/dev/null
        adb -s "$device_id" reverse "tcp:${kitPort}" "tcp:${kitPort}" >/dev/null
        echo "Android reverse port ready for $device_id: ${kitPort}"
      '';
      description = "Expose the local LeptosKit server port to the connected Android device over adb reverse.";
      binary = "bash";
    };
    "dev:seeker" = {
      exec = ''
        set -euo pipefail
        device_id="''${SEEKER_DEVICE_ID:-SM02E4060324957}"
        adb -s "$device_id" get-state >/dev/null
        android:reverse "$device_id"
        if ! devenv processes list >/dev/null 2>&1; then
          devenv up -d
        fi
        echo "Waiting for Verily server on localhost:${kitPort}..."
        for _ in $(seq 1 60); do
          if nc -z 127.0.0.1 ${kitPort} >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done
        if ! nc -z 127.0.0.1 ${kitPort} >/dev/null 2>&1; then
          echo "Verily server did not open port ${kitPort} in time. Check: devenv processes logs server:up" >&2
          exit 1
        fi
        cd "$DEVENV_ROOT/${kitDir}"
        export VERILY_API_ORIGIN="http://127.0.0.1:${kitPort}"
        exec lk run android --device "$device_id"
      '';
      description = "Start PostGIS, the LeptosKit server, adb reverse, and launch the Android host on Seeker.";
      binary = "bash";
    };
    "dev:seeker:stop" = {
      exec = ''
        set -euo pipefail
        device_id="''${SEEKER_DEVICE_ID:-SM02E4060324957}"
        adb -s "$device_id" shell am force-stop ${appId} >/dev/null 2>&1 || true
        devenv processes down || true
      '';
      description = "Stop the Seeker Android app and background devenv processes.";
      binary = "bash";
    };
    "dev:seeker:status" = {
      exec = ''
        set -euo pipefail
        devenv processes list || true
        adb devices
      '';
      description = "Show local devenv process and Android device status.";
      binary = "bash";
    };
    "cargo-build-sbf" = {
      exec = ''
        set -euo pipefail
        export PATH="${pkgs.rustup}/bin:$PATH"
        exec ${extra.agave}/bin/cargo-build-sbf "$@"
      '';
      description = "Run Nix-pinned Agave cargo-build-sbf through the rustup cargo proxy required by platform-tools.";
      binary = "bash";
      packages = [ pkgs.rustup ];
    };
    "build:escrow" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        mkdir -p target/deploy target/idl
        cargo-build-sbf \
          --lto \
          --manifest-path programs/verily_escrow_sbf/Cargo.toml \
          --sbf-out-dir target/deploy \
          --no-default-features \
          --features bpf-entrypoint
        pina idl \
          --path programs/verily_escrow \
          --output target/idl/verily_escrow.json
      '';
      description = "Build the reward escrow program with Agave's pinned SBF toolchain and refresh its Pina IDL.";
      binary = "bash";
      packages = [
        config.scripts."cargo-build-sbf".scriptPackage
        pinaPkgs.pina
      ];
    };
    "test:kit" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT/${kitDir}"
        ${rustToolchain}/bin/cargo check --bin verily-kit --locked
        ${rustToolchain}/bin/cargo test \
          -p verily_shared \
          -p verily_api \
          -p verily_ink \
          -p verily_site \
          -p verily_attest \
          -p verily_capture \
          -p verily_verification \
          -p verily_rewards \
          -p verily_backend \
          -p verily_app \
          --locked
      '';
      description = "Check the verily-kit server binary and run every portable crate test suite in verily_kit.";
      binary = "bash";
      packages = [ rustToolchain ];
    };
    "test:escrow" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        ${rustToolchain}/bin/cargo test -p verily_escrow --locked
        build:escrow
        RUST_LOG="''${RUST_LOG:-error}" ${rustToolchain}/bin/cargo test \
          --manifest-path programs/verily_escrow/tests/mollusk/Cargo.toml \
          --locked
      '';
      description = "Build the reward escrow program and run its unit and Mollusk suites.";
      binary = "bash";
      packages = [
        rustToolchain
        config.scripts."build:escrow".scriptPackage
      ];
    };
    "test:all" = {
      exec = ''
        set -e
        test:kit
        test:escrow
      '';
      description = "Run verily_kit and reward escrow program test suites.";
      binary = "bash";
      packages = [
        config.scripts."test:kit".scriptPackage
        config.scripts."test:escrow".scriptPackage
      ];
    };
    "test:server-image" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        if ! docker info >/dev/null 2>&1; then
          echo "test:server-image needs a running Docker or Podman machine." >&2
          exit 69
        fi
        export BUILDAH_FORMAT=docker
        docker build --platform linux/amd64 --file verily_kit/Dockerfile --tag verily-kit:local .

        free_port() {
          local port="$1"
          while nc -z 127.0.0.1 "$port" >/dev/null 2>&1; do
            port=$((port + 1))
          done
          echo "$port"
        }
        export VERILY_POSTGRES_PORT="$(free_port 18191)"
        export VERILY_KIT_PORT="$(free_port 18184)"
        secret() { openssl rand -base64 "$1"; }
        export AUTH_ENCRYPTION_KEYS="$(openssl rand -hex 32)"
        export VERILY_ABUSE_RISK_SALT="$(secret 32)"
        export VERILY_RECEIPT_SIGNING_PRIVATE_KEY="$(secret 32)"
        export VERILY_EVIDENCE_STORAGE_MODE="b2"
        export VERILY_B2_ENDPOINT="https://s3.us-west-004.backblazeb2.com"
        export VERILY_B2_REGION="us-west-004"
        export VERILY_B2_BUCKET="verily-image-check"
        export VERILY_B2_KEY_ID="image-check"
        export VERILY_B2_APPLICATION_KEY="$(secret 24)"

        compose=(docker compose --file "$DEVENV_ROOT/${kitDir}/docker-compose.yaml"
          --project-name verily-image-check --profile server)
        trap '"''${compose[@]}" down --volumes >/dev/null 2>&1 || true' EXIT
        "''${compose[@]}" up --detach --no-build server
        boot_started=$SECONDS
        healthy=false
        for _ in $(seq 1 90); do
          if curl --fail --silent --show-error \
            "http://127.0.0.1:$VERILY_KIT_PORT/healthz" >/dev/null 2>&1; then
            healthy=true
            break
          fi
          sleep 2
        done
        if [ "$healthy" != true ]; then
          "''${compose[@]}" logs server >&2
          echo "The production image did not become healthy." >&2
          exit 1
        fi
        echo "The production image is serving /healthz after $((SECONDS - boot_started))s."
      '';
      description = "Build the linux/amd64 verily-kit Docker image and boot it against PostGIS.";
      binary = "bash";
      packages = [
        pkgs.curl
        pkgs.netcat
        pkgs.openssl
      ];
    };
    "site:build" = {
      exec = ''
        set -euo pipefail
        out="''${1:-$DEVENV_ROOT/${kitDir}/dist/site}"
        cd "$DEVENV_ROOT/${kitDir}"
        ${rustToolchain}/bin/cargo run --release --package verily_site -- "$out"
      '';
      description = "Render verily.fun, the landing page, to static files (default verily_kit/dist/site).";
      binary = "bash";
    };
    "site:serve" = {
      exec = ''
        set -euo pipefail
        out="$DEVENV_ROOT/${kitDir}/dist/site"
        site:build "$out"
        echo "verily.fun on http://127.0.0.1:${sitePort}"
        ${pkgs.python3}/bin/python3 -m http.server ${sitePort} --bind 127.0.0.1 --directory "$out"
      '';
      description = "Render the landing page and serve it on port ${sitePort}.";
      binary = "bash";
      packages = [ config.scripts."site:build".scriptPackage ];
    };
    "lint:kit" = {
      exec = ''
        set -euo pipefail
        if ! command -v lk >/dev/null 2>&1; then
          echo "lk is not on PATH. Install it from the pinned leptoskit rev:" >&2
          echo "  cargo install --git https://github.com/leptoskit/leptoskit --rev ${leptoskitRev} leptoskit_cli --locked" >&2
          exit 1
        fi
        cd "$DEVENV_ROOT/${kitDir}"
        lk lint
      '';
      description = "Lint the verily_kit workspace with the LeptosKit CLI.";
      binary = "bash";
    };
    "audit:rust" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        dependency_graph="$(${rustToolchain}/bin/cargo tree \
          --workspace \
          --all-features \
          --target all \
          --prefix none \
          --format '{p}')"
        forbidden_packages='^(bincode|derivative|libsecp256k1|paste) v'
        if printf '%s\n' "$dependency_graph" | ${pkgs.gnugrep}/bin/grep -Eq "$forbidden_packages"; then
          echo "A forbidden Rust dependency reached the escrow workspace graph:" >&2
          printf '%s\n' "$dependency_graph" | ${pkgs.gnugrep}/bin/grep -E "$forbidden_packages" >&2
          exit 1
        fi
        ${pkgs.cargo-audit}/bin/cargo-audit audit
      '';
      description = "Audit Rust dependencies and reject obsolete serialization, macro, and secp256k1 crates.";
      binary = "bash";
      packages = [
        rustToolchain
        pkgs.cargo-audit
      ];
    };
    "lint:programs" = {
      exec = ''
        set -euo pipefail
        audit:rust
        ${rustToolchain}/bin/cargo clippy \
          --workspace \
          --all-targets \
          -- \
          -D warnings
        ${rustToolchain}/bin/cargo clippy \
          --manifest-path "$DEVENV_ROOT/programs/verily_escrow/tests/mollusk/Cargo.toml" \
          --all-targets \
          --locked \
          -- \
          -D warnings
        CC=${pinaLintCc} CXX=${pinaLintCxx} \
          RUSTFLAGS="''${RUSTFLAGS:+$RUSTFLAGS }-C linker=${pinaLintCc}" \
          pina lint --project "$DEVENV_ROOT/programs/verily_escrow"
        (
          cd "$DEVENV_ROOT/programs/verily_escrow"
          pina migrations check
        )
      '';
      description = "Audit dependencies, run Clippy and Pina security lints, and check the escrow program's migrations.";
      binary = "bash";
      packages = [
        config.scripts."audit:rust".scriptPackage
        rustToolchain
        pinaPkgs.pina
      ];
    };
    "lint:format" = {
      exec = ''
        set -euo pipefail
        dprint check
        nixfmt --check devenv.nix
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --all -- --check
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --manifest-path "$DEVENV_ROOT/${kitDir}/Cargo.toml" --all -- --check
      '';
      description = "Check project formatting with the pinned toolchains.";
      binary = "bash";
      packages = [
        pkgs.dprint
        pkgs.nixfmt
        rustToolchain
      ];
    };
    "lint:native" = {
      exec = ''
        set -e
        mapfile -t kotlin_files < <(
          find "$DEVENV_ROOT/${kitDir}/android" \
            "$DEVENV_ROOT/${kitDir}/verily_attest/android" \
            "$DEVENV_ROOT/${kitDir}/verily_capture/android" \
            \( -name '*.kt' -o -name '*.kts' \) -type f 2>/dev/null | sort
        )
        if [ "''${#kotlin_files[@]}" -gt 0 ]; then
          ktlint "''${kotlin_files[@]}"
        fi
        if command -v swiftlint >/dev/null 2>&1; then
          if xcode-select -p 2>/dev/null | grep -q CommandLineTools; then
            echo "Skipping swiftlint (requires full Xcode for sourcekitd; Command Line Tools only)."
          else
            swiftlint lint --strict \
              "$DEVENV_ROOT/${kitDir}/ios" \
              "$DEVENV_ROOT/${kitDir}/verily_attest/apple" \
              "$DEVENV_ROOT/${kitDir}/verily_capture/apple"
          fi
        else
          echo "Skipping swiftlint (not available on this platform)."
        fi
      '';
      description = "Run native Android and iOS linters on LeptosKit host and plugin sources.";
      binary = "bash";
      packages = [ pkgs.ktlint ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.swiftlint ];
    };
    "lint:all" = {
      exec = ''
        set -e
        lint:format
        lint:programs
        lint:native
        lint:kit
      '';
      description = "Run all lint checks.";
      binary = "bash";
      packages = [
        config.scripts."lint:format".scriptPackage
        config.scripts."lint:programs".scriptPackage
        config.scripts."lint:native".scriptPackage
        config.scripts."lint:kit".scriptPackage
      ];
    };
    "fix:format" = {
      exec = ''
        set -e
        dprint fmt --config "$DEVENV_ROOT/dprint.json"
        nixfmt devenv.nix
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --all
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --manifest-path "$DEVENV_ROOT/${kitDir}/Cargo.toml" --all
      '';
      description = "Format project files.";
      binary = "bash";
    };
    "fix:all" = {
      exec = ''
        set -e
        fix:format
      '';
      description = "Fix all autofixable issues.";
      binary = "bash";
    };
    "clean:all" = {
      exec = ''
        set -e
        ${rustToolchain}/bin/cargo clean
        ${rustToolchain}/bin/cargo clean --manifest-path "$DEVENV_ROOT/${kitDir}/Cargo.toml"
      '';
      description = "Clean Rust build artifacts.";
      binary = "bash";
    };
  };
}
