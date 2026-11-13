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
  serverpodPkgs = inputs.ifiokjr-nixpkgs-serverpod.packages.${pkgs.stdenv.system};
  pinaPkgs = inputs.ifiokjr-nixpkgs-pina.packages.${pkgs.stdenv.system};
  # Pina lint drivers are tied to one rustc revision. Keep this aligned with
  # Pina 0.23.0's published driver so the security-lint lane cannot disappear.
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
  appDir = "verily_flutter";
  serverDir = "verily_server";
  appId = "fun.verily.app";
  # Verily runs beside other local Serverpod projects, so it avoids the
  # default 8080-8082 and 8091 ports.
  apiPort = "8180";
  insightsPort = "8181";
  webPort = "8182";
  postgresPort = 8191;
  devenvGitHook =
    name: script: arguments:
    pkgs.writeShellScript name ''
      set -euo pipefail
      project_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      cd "$project_root"
      export DEVENV_ROOT="$project_root"
      exec "${config.env.DEVENV_PROFILE}/bin/${script}" ${arguments} "$@"
    '';
  resolveFlutterSdk = ''
    # Git hooks export repository-local variables. Flutter invokes Git inside
    # its SDK to determine its own version, so those variables must not leak
    # across the repository boundary.
    unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG GIT_CONFIG_PARAMETERS
    unset GIT_CONFIG_COUNT GIT_OBJECT_DIRECTORY GIT_DIR GIT_WORK_TREE
    unset GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_INDEX_FILE
    unset GIT_NO_REPLACE_OBJECTS GIT_REPLACE_REF_BASE GIT_PREFIX
    unset GIT_SHALLOW_FILE GIT_COMMON_DIR

    if [ "''${CI:-}" = "true" ] && [ -x "''${FLUTTER_ROOT:-}/bin/flutter" ]; then
      flutter_sdk="''${FLUTTER_ROOT}"
    else
      flutter_version="$(awk -F'"' '/"flutter"/ { print $4; exit }' "$DEVENV_ROOT/.fvmrc")"
      if ! [[ "$flutter_version" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "The Flutter version in .fvmrc is missing or invalid." >&2
        exit 1
      fi

      local_flutter_sdk="$DEVENV_ROOT/.fvm/flutter_sdk"
      fvm_cache_root="''${FVM_CACHE_PATH:-''${FVM_HOME:-$HOME/fvm}}"
      cached_flutter_sdk="$fvm_cache_root/versions/$flutter_version"
      if [ -x "$local_flutter_sdk/bin/flutter" ]; then
        # An FVM symlink left on an older release silently disagrees with the
        # pinned version, so refuse to run instead.
        linked_flutter_version="$(cat "$DEVENV_ROOT/.fvm/version" 2>/dev/null || true)"
        if [ "$linked_flutter_version" != "$flutter_version" ]; then
          echo ".fvm/flutter_sdk is $linked_flutter_version but .fvmrc pins $flutter_version." >&2
          echo "Run: fvm use $flutter_version" >&2
          exit 1
        fi
        flutter_sdk="$local_flutter_sdk"
      elif [ -x "$cached_flutter_sdk/bin/flutter" ]; then
        flutter_sdk="$cached_flutter_sdk"
      else
        echo "Flutter $flutter_version is not installed. Run: fvm install $flutter_version" >&2
        exit 1
      fi
    fi
  '';
  # Nix toolchain variables break Xcode and host build hooks.
  scrubNixToolchain = ''
    unset CC CXX LD AR NM RANLIB STRIP OBJCOPY OBJDUMP SIZE STRINGS
    unset NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE NIX_LDFLAGS
    unset NIX_HARDENING_ENABLE NIX_ENFORCE_NO_NATIVE
    unset NIX_DONT_SET_RPATH NIX_DONT_SET_RPATH_FOR_BUILD NIX_NO_SELF_RPATH
    unset NIX_IGNORE_LD_THROUGH_GCC
    unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_arm64_apple_darwin
    unset NIX_CC_WRAPPER_TARGET_HOST_arm64_apple_darwin
    unset NIX_PKG_CONFIG_WRAPPER_TARGET_HOST_arm64_apple_darwin
    unset SDKROOT MACOSX_DEPLOYMENT_TARGET
    unset CFLAGS CXXFLAGS LDFLAGS ARCHFLAGS
    unset PKG_CONFIG PKG_CONFIG_PATH
    unset LD_LIBRARY_PATH LD_DYLD_PATH
    unset cmakeFlags
  '';
  # Reads the port of this checkout's running Postgres from its pid file, so
  # several worktrees can each run a private database.
  resolvePostgresPort = ''
    postgres_pid_file="$DEVENV_ROOT/.devenv/state/postgres/postmaster.pid"
    postgres_port="''${SERVERPOD_DATABASE_PORT:-''${PGPORT:-${toString postgresPort}}}"
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
      fvm
      gitleaks
      jq
      ktlint
      netcat
      nixfmt
      nodejs
      pnpm
      shfmt
      rustToolchain
      extra.agave
      pinaPkgs.pina
      extra.sbpf-linker
      serverpodPkgs."serverpod_cli-4"
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
    ];

  dotenv.disableHint = true;

  env = {
    SBF_TOOLS_VERSION = "v1.54";
  };

  # Rely on the global Apple SDK; the Nix Apple SDK conflicts with Flutter/Xcode builds.
  apple.sdk = null;

  services = {
    postgres = {
      enable = !isCI;
      package = pkgs.postgresql_16;
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
      lint = {
        enable = true;
        name = "lint";
        description = "Run Dart analysis before commit.";
        entry = "${devenvGitHook "verily-analyze-hook" "dart" "analyze --no-fatal-warnings"}";
        pass_filenames = true;
        require_serial = true;
        files = "\\.dart$";
        excludes = [
          "\\.(g|freezed)\\.dart$"
          "/generated/"
          "/protocol/"
          "serverpod_test_tools\\.dart$"
        ];
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
    "flutter" = {
      exec = ''
        set -e
        ${scrubNixToolchain}
        ${resolveFlutterSdk}
        "$flutter_sdk/bin/flutter" "$@"
      '';
      description = "Run Flutter commands through FVM with Xcode-safe environment cleanup.";
      binary = "bash";
      packages = [ pkgs.fvm ];
    };
    "dart" = {
      exec = ''
        set -e
        ${scrubNixToolchain}
        # Host build hooks run a bare `clang` PATH lookup, and Nix's clang
        # cannot link the macOS dylibs they build.
        ${lib.optionalString pkgs.stdenv.isDarwin ''export PATH="/usr/bin:$PATH"''}
        ${resolveFlutterSdk}
        "$flutter_sdk/bin/dart" "$@"
      '';
      description = "Run Dart commands through FVM.";
      binary = "bash";
      packages = [ pkgs.fvm ];
    };
    "flutter:app" = {
      exec = ''
        set -e
        cd "$DEVENV_ROOT/${appDir}"
        flutter "$@"
      '';
      description = "Run Flutter commands from the app package.";
      binary = "bash";
    };
    "install:all" = {
      exec = ''
        set -e
        flutter pub get
        clients:install
      '';
      description = "Install Dart, Flutter, and client-generator dependencies.";
      binary = "bash";
      packages = [
        config.scripts.flutter.scriptPackage
        config.scripts."clients:install".scriptPackage
      ];
    };
    "server:start" = {
      exec = ''
        set -euo pipefail
        export MONOSECRET_PROFILE="''${MONOSECRET_PROFILE:-development}"
        export runmode=development
        export SERVERPOD_API_SERVER_PORT="''${SERVERPOD_API_SERVER_PORT:-${apiPort}}"
        export SERVERPOD_API_SERVER_PUBLIC_PORT="''${SERVERPOD_API_SERVER_PUBLIC_PORT:-${apiPort}}"
        export SERVERPOD_INSIGHTS_SERVER_PORT="''${SERVERPOD_INSIGHTS_SERVER_PORT:-${insightsPort}}"
        export SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT="''${SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT:-${insightsPort}}"
        export SERVERPOD_WEB_SERVER_PORT="''${SERVERPOD_WEB_SERVER_PORT:-${webPort}}"
        export SERVERPOD_WEB_SERVER_PUBLIC_PORT="''${SERVERPOD_WEB_SERVER_PUBLIC_PORT:-${webPort}}"
        export SERVERPOD_DATABASE_NAME="''${SERVERPOD_DATABASE_NAME:-verily}"
        ${resolvePostgresPort}
        export SERVERPOD_DATABASE_PORT="$postgres_port"
        ${onePasswordSandbox}
        cd "$DEVENV_ROOT/${serverDir}"
        exec dart bin/main.dart --mode development --apply-migrations
      '';
      description = "Start the Serverpod development server.";
      binary = "bash";
    };
    "secrets:check" = {
      exec = ''
        set -euo pipefail
        ${onePasswordSandbox}
        cd "$DEVENV_ROOT"
        exec monosecret check \
          --profile development \
          --reason "validate Verily development secrets"
      '';
      description = "Validate the dotenv-first Monosecret development profile without printing values.";
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
        for port in ${apiPort} ${insightsPort} ${webPort}; do
          adb -s "$device_id" reverse "tcp:$port" "tcp:$port" >/dev/null
        done

        echo "Android reverse ports ready for $device_id: ${apiPort}, ${insightsPort}, ${webPort}"
      '';
      description = "Expose local Serverpod ports to the connected Android device over adb reverse.";
      binary = "bash";
    };
    "android:jdk" = {
      exec = ''
        set -euo pipefail
        if [ "$#" -eq 0 ]; then
          echo "usage: android:jdk <command> [args...]" >&2
          exit 64
        fi

        # Hand Java tools the JDK Flutter builds Android with, not whatever
        # `java` resolves to on PATH.
        jdk_dir="$(flutter --suppress-analytics config --machine | jq -r '."jdk-dir" // empty')"
        if [ -z "$jdk_dir" ] || [ ! -x "$jdk_dir/bin/java" ]; then
          echo "Flutter found no JDK for Android builds." >&2
          echo "Install Android Studio, set JAVA_HOME, or run: flutter config --jdk-dir <path>" >&2
          exit 1
        fi
        export JAVA_HOME="$jdk_dir"
        export PATH="$JAVA_HOME/bin:$PATH"
        exec "$@"
      '';
      description = "Run a command with JAVA_HOME set to the JDK Flutter builds Android with.";
      binary = "bash";
      packages = [
        config.scripts.flutter.scriptPackage
        pkgs.jq
      ];
    };
    "dev:seeker" = {
      exec = ''
        set -euo pipefail
        device_id="''${SEEKER_DEVICE_ID:-SM02E4060324957}"
        log_dir="$DEVENV_ROOT/.devlogs"
        flutter_log="$log_dir/seeker-flutter.log"
        tmux_session="verily-seeker"
        driver_text_emulation="''${FLUTTER_DRIVER_TEXT_EMULATION:-false}"
        play_integrity_project_number="''${VERILY_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER:-}"

        mkdir -p "$log_dir"

        adb -s "$device_id" get-state >/dev/null
        android:reverse "$device_id"

        echo "Starting Postgres and Serverpod in the background..."
        if devenv processes list >/dev/null 2>&1; then
          echo "devenv processes are already running."
        else
          devenv up -d
        fi

        echo "Waiting for Serverpod on localhost:${apiPort}..."
        for _ in $(seq 1 60); do
          if nc -z 127.0.0.1 ${apiPort} >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        if ! nc -z 127.0.0.1 ${apiPort} >/dev/null 2>&1; then
          echo "Serverpod did not open port ${apiPort} in time. Check: devenv processes logs server:up" >&2
          exit 1
        fi

        if tmux has-session -t "$tmux_session" 2>/dev/null; then
          echo "Seeker Flutter app is already running in tmux session $tmux_session."
          echo "Logs: $flutter_log"
          exit 0
        fi

        echo "Launching Flutter on Seeker ($device_id) in the background..."
        cd "$DEVENV_ROOT/${appDir}"
        tmux new-session -d -s "$tmux_session" bash -lc \
          "exec flutter run -t lib/driver_main.dart -d '$device_id' \
          --dart-define=SERVER_URL=http://localhost:${apiPort}/ \
          --dart-define=VERILY_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER='$play_integrity_project_number' \
          --dart-define=FLUTTER_DRIVER_TEXT_EMULATION='$driver_text_emulation' \
          > '$flutter_log' 2>&1"

        echo "Seeker dev environment is starting."
        echo "Flutter tmux session: $tmux_session"
        echo "Flutter log: $flutter_log"
        echo "Server logs: devenv processes logs server:up"
        echo "Hot reload: devenv shell dev:seeker:reload"
        echo "Stop: devenv shell dev:seeker:stop"
      '';
      description = "Start Postgres, Serverpod, adb reverse ports, and the Flutter app on the Seeker Android device in the background.";
      binary = "bash";
    };
    "dev:seeker:mcp" = {
      exec = ''
        set -euo pipefail
        dev:seeker:stop
        FLUTTER_DRIVER_TEXT_EMULATION=true dev:seeker
      '';
      description = "Restart Seeker with Flutter Driver text entry emulation enabled for MCP text automation.";
      binary = "bash";
    };
    "dev:seeker:status" = {
      exec = ''
        set -euo pipefail
        devenv processes list || true
        if tmux has-session -t verily-seeker 2>/dev/null; then
          echo "Seeker Flutter app: running (tmux session verily-seeker)"
        else
          echo "Seeker Flutter app: not running"
        fi
        adb devices
      '';
      description = "Show Seeker dev process and Android device status.";
      binary = "bash";
    };
    "dev:seeker:reload" = {
      exec = ''
        set -euo pipefail
        if ! tmux has-session -t verily-seeker 2>/dev/null; then
          echo "Seeker Flutter runner is not running. Start it with: devenv shell dev:seeker" >&2
          exit 1
        fi
        tmux send-keys -t verily-seeker r
        echo "Requested Flutter hot reload."
      '';
      description = "Trigger hot reload for the background Seeker Flutter runner.";
      binary = "bash";
    };
    "dev:seeker:hot-restart" = {
      exec = ''
        set -euo pipefail
        if ! tmux has-session -t verily-seeker 2>/dev/null; then
          echo "Seeker Flutter runner is not running. Start it with: devenv shell dev:seeker" >&2
          exit 1
        fi
        tmux send-keys -t verily-seeker R
        echo "Requested Flutter hot restart."
      '';
      description = "Trigger hot restart for the background Seeker Flutter runner.";
      binary = "bash";
    };
    "dev:seeker:stop" = {
      exec = ''
        set -euo pipefail
        device_id="''${SEEKER_DEVICE_ID:-SM02E4060324957}"
        if tmux has-session -t verily-seeker 2>/dev/null; then
          tmux kill-session -t verily-seeker
          echo "Stopped Seeker Flutter runner."
        else
          echo "Seeker Flutter runner was not running."
        fi
        adb -s "$device_id" shell am force-stop ${appId} >/dev/null 2>&1 || true
        devenv processes down || true
      '';
      description = "Stop the Seeker Flutter app and background devenv processes.";
      binary = "bash";
    };
    "dev:seeker:restart" = {
      exec = ''
        set -euo pipefail
        dev:seeker:stop
        dev:seeker
      '';
      description = "Restart the Seeker Flutter app and background devenv processes.";
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
    "test:escrow" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        ${rustToolchain}/bin/cargo test -p verily_escrow --locked
        build:escrow
        # The Mollusk suite runs the compiled program against the real SPL
        # Token programs. It is its own Cargo workspace because Mollusk pulls
        # crates that `audit:rust` forbids in the main workspace. Mollusk logs
        # every instruction at debug level; that volume overwhelms the
        # pre-push hook runner, so only errors are printed here.
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
    "test:escrow:e2e" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        build:escrow
        ${resolvePostgresPort}
        if ! nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
          echo "Starting devenv processes so Postgres is available for the escrow end-to-end test..."
          devenv up -d
        fi
        for _ in $(seq 1 60); do
          ${resolvePostgresPort}
          if nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done
        if ! nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
          echo "Postgres did not open port $postgres_port in time. Check: devenv processes logs postgres" >&2
          exit 1
        fi

        # The test starts its own throwaway solana-test-validator with the
        # program at its reviewed address and stops it when it finishes.
        export SERVERPOD_DATABASE_PORT="$postgres_port"
        export VERILY_ESCROW_E2E_PROGRAM="$DEVENV_ROOT/target/deploy/verily_escrow.so"
        export VERILY_ESCROW_E2E_VALIDATOR="${extra.agave}/bin/solana-test-validator"
        cd "$DEVENV_ROOT/${serverDir}"
        dart run tool/test_with_secrets.dart --concurrency=1 test/e2e
      '';
      description = "Build the reward escrow program, load it into a throwaway local validator, and run the Solana gateway end to end against Postgres.";
      binary = "bash";
      packages = [
        pkgs.netcat
        extra.agave
        config.scripts."build:escrow".scriptPackage
        config.scripts.dart.scriptPackage
      ];
    };
    "test:all" = {
      exec = ''
        set -e
        test:tools
        test:lints
        test:escrow
        test:flutter
        test:server
      '';
      description = "Run tooling, lint-rule, escrow program, Flutter, and Serverpod tests.";
      binary = "bash";
      packages = [
        config.scripts."test:tools".scriptPackage
        config.scripts."test:lints".scriptPackage
        config.scripts."test:escrow".scriptPackage
        config.scripts."test:flutter".scriptPackage
        config.scripts."test:server".scriptPackage
      ];
    };
    "test:tools" = {
      exec = ''
        set -e
        cd "$DEVENV_ROOT"
        dart test test/tool
      '';
      description = "Run the repository tooling tests, such as local CI's lane table.";
      binary = "bash";
      packages = [ config.scripts.dart.scriptPackage ];
    };
    "test:lints" = {
      exec = ''
        set -e
        cd "$DEVENV_ROOT/packages/verily_lints"
        flutter pub run test
      '';
      description = "Run the Verily analyzer plugin rule tests.";
      binary = "bash";
      packages = [ config.scripts.flutter.scriptPackage ];
    };
    "test:flutter" = {
      exec = ''
        set -e
        cd "$DEVENV_ROOT/${appDir}"
        flutter test test
        cd "$DEVENV_ROOT/packages/verily_brand"
        flutter test test
      '';
      description = "Run Flutter unit and widget tests for the app and brand packages.";
      binary = "bash";
      packages = [ config.scripts.flutter.scriptPackage ];
    };
    "test:server" = {
      exec = ''
        set -euo pipefail
        ${resolvePostgresPort}

        if ! nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
          echo "Starting devenv processes so Postgres is available for Serverpod tests..."
          devenv up -d
        fi

        echo "Waiting for this checkout's Postgres on localhost:$postgres_port..."
        for _ in $(seq 1 60); do
          ${resolvePostgresPort}
          if nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        if ! nc -z 127.0.0.1 "$postgres_port" >/dev/null 2>&1; then
          echo "Postgres did not open port $postgres_port in time. Check: devenv processes logs postgres" >&2
          exit 1
        fi

        export SERVERPOD_DATABASE_PORT="$postgres_port"
        cd "$DEVENV_ROOT/${serverDir}"
        dart run tool/test_with_secrets.dart \
          --concurrency=1 \
          test/unit \
          test/integration
        cd "$DEVENV_ROOT/packages/verily_evidence"
        dart test
      '';
      description = "Run Serverpod and shared evidence tests through the Monosecret test profile, starting local Postgres when needed.";
      binary = "bash";
      packages = [
        pkgs.netcat
        config.scripts.dart.scriptPackage
      ];
    };
    "test:server-image" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        # The host's Docker engine (Docker, OrbStack, or a podman machine)
        # builds the image. MediaPipe's runtime is published for Linux x64
        # only, so the image is linux/amd64 everywhere.
        if ! docker info >/dev/null 2>&1; then
          echo "test:server-image needs a running Docker or Podman machine:" \
            "\`docker info\` cannot reach one. Start it (for example" \
            "\`podman machine start\`) and run this lane again." >&2
          exit 69
        fi
        # Podman builds OCI images by default, which drop HEALTHCHECK; build
        # the Docker format a deployment receives. Docker ignores this.
        export BUILDAH_FORMAT=docker
        build() {
          docker build --platform linux/amd64 --file verily_server/Dockerfile \
            --target "$1" --tag "$2" .
        }
        build local-check-replay verily-server:local-check-replay
        build production verily-server:local

        echo "Replaying pinned fixtures on the image's MediaPipe runtime..."
        docker run --rm --platform linux/amd64 verily-server:local-check-replay

        echo "Booting the production image against PostGIS with migrations..."
        free_port() {
          local port="$1"
          while nc -z 127.0.0.1 "$port" >/dev/null 2>&1; do
            port=$((port + 1))
          done
          echo "$port"
        }
        export VERILY_POSTGRES_PORT="$(free_port 18191)"
        export VERILY_SERVER_WEB_PORT="$(free_port 18182)"
        # Throwaway values for the secrets production requires. Backblaze is
        # configured, as production demands, with a valid-shaped origin and
        # keys that do not exist; booting never contacts the bucket.
        secret() { openssl rand -base64 "$1"; }
        export SERVERPOD_DATABASE_PASSWORD="$(secret 24)"
        export SERVERPOD_SERVICE_SECRET="$(secret 48)"
        export SERVERPOD_PASSWORD_emailSecretHashPepper="$(secret 48)"
        export SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="$(secret 64)"
        export SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="$(secret 48)"
        export VERILY_EVIDENCE_B2_S3_ENDPOINT="https://s3.us-west-004.backblazeb2.com"
        export VERILY_EVIDENCE_B2_REGION="us-west-004"
        export VERILY_EVIDENCE_B2_BUCKET_NAME="verily-image-check"
        export VERILY_EVIDENCE_B2_KEY_ID="image-check"
        export VERILY_EVIDENCE_B2_APPLICATION_KEY="$(secret 24)"
        export VERILY_WEBHOOK_SIGNING_MASTER_KEY="$(secret 48)"
        export VERILY_RECEIPT_SIGNING_KEY="$(secret 32)"
        # An absolute path: the cleanup trap runs after the cd below.
        compose=(docker compose --file "$DEVENV_ROOT/${serverDir}/docker-compose.yaml"
          --project-name verily-image-check --profile server)
        trap '"''${compose[@]}" down --volumes >/dev/null 2>&1 || true' EXIT
        "''${compose[@]}" up --detach --no-build server
        boot_started=$SECONDS
        healthy=false
        for _ in $(seq 1 90); do
          if curl --fail --silent --show-error \
            "http://127.0.0.1:$VERILY_SERVER_WEB_PORT/healthz" >/dev/null 2>&1; then
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

        echo "Checking the migrated schema contracts..."
        cd "$DEVENV_ROOT/${serverDir}"
        SERVERPOD_DATABASE_HOST=127.0.0.1 \
          SERVERPOD_DATABASE_PORT="$VERILY_POSTGRES_PORT" \
          SERVERPOD_DATABASE_NAME=verily \
          dart run tool/verify_schema_contracts.dart
      '';
      description = "Build the linux/amd64 server image, replay local checks on its MediaPipe runtime, and boot it against PostGIS with migrations.";
      binary = "bash";
      packages = [
        pkgs.curl
        pkgs.netcat
        pkgs.openssl
        pkgs.postgresql_16
        config.scripts.dart.scriptPackage
      ];
    };
    "lint:analyze" = {
      exec = ''
        set -e
        cd "$DEVENV_ROOT"
        dart analyze .
        cd "$DEVENV_ROOT/${appDir}"
        dart analyze .
      '';
      description = "Analyze the workspace and enforce Verily's Flutter analyzer plugin.";
      binary = "bash";
      packages = [ config.scripts.dart.scriptPackage ];
    };
    "lint:all" = {
      exec = ''
        set -e
        lint:format
        lint:analyze
        lint:programs
        lint:native
        lint:kit
      '';
      description = "Run all lint checks.";
      binary = "bash";
      packages = [
        config.scripts."lint:format".scriptPackage
        config.scripts."lint:analyze".scriptPackage
        config.scripts."lint:programs".scriptPackage
        config.scripts."lint:native".scriptPackage
        config.scripts."lint:kit".scriptPackage
      ];
    };
    "site:build" = {
      exec = ''
        set -euo pipefail
        out="''${1:-$DEVENV_ROOT/verily_kit/dist/site}"
        cd "$DEVENV_ROOT/verily_kit"
        cargo run --release --package verily_site -- "$out"
      '';
      description = "Render verily.fun, the landing page, to static files (default verily_kit/dist/site).";
      binary = "bash";
    };
    "site:serve" = {
      exec = ''
        set -euo pipefail
        out="$DEVENV_ROOT/verily_kit/dist/site"
        site:build "$out"
        echo "verily.fun on http://127.0.0.1:8183"
        ${pkgs.python3}/bin/python3 -m http.server 8183 --bind 127.0.0.1 --directory "$out"
      '';
      description = "Render the landing page and serve it on port 8183.";
      binary = "bash";
      packages = [ config.scripts."site:build".scriptPackage ];
    };
    "lint:kit" = {
      exec = ''
        set -euo pipefail
        if ! command -v lk >/dev/null 2>&1; then
          echo "lk is not on PATH. Install it from the pinned leptoskit rev: cargo install --git https://github.com/ifiokjr/leptoskit --rev b150c5778ef428d38c122860d004523df9208350 leptoskit_cli --locked" >&2
          exit 1
        fi
        cd "$DEVENV_ROOT/verily_kit"
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
          echo "A forbidden Rust dependency reached the workspace graph:" >&2
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
    "clients:install" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        pnpm install --frozen-lockfile
      '';
      description = "Install the pinned Codama renderers that `pina generate` drives.";
      binary = "bash";
      packages = [
        pkgs.nodejs
        pkgs.pnpm
      ];
    };
    "clients:generate" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        if [ ! -d node_modules/codama-renderers-dart ]; then
          clients:install
        fi
        # Pina rejects `..` in configured paths, so the package root is pinned
        # here with `--output packages`; `[clients.dart].output` names it.
        pina generate --project programs/verily_escrow --client dart --output packages --npx node
        # The renderer emits unformatted Dart; format before committing.
        dart format --trailing-commas=preserve packages/verily_escrow_client
      '';
      description = "Regenerate the escrow program's Dart client package.";
      binary = "bash";
      packages = [
        pinaPkgs.pina
        config.scripts.dart.scriptPackage
        config.scripts."clients:install".scriptPackage
      ];
    };
    "clients:check" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT"
        clients:generate
        if [ -n "$(git status --porcelain -- packages/verily_escrow_client)" ]; then
          echo "Generated clients differ from the committed output:" >&2
          git status --porcelain -- packages/verily_escrow_client >&2
          exit 1
        fi
      '';
      description = "Fail when the committed Pina client drifts from a fresh `pina generate`.";
      binary = "bash";
      packages = [ config.scripts."clients:generate".scriptPackage ];
    };
    "lint:format" = {
      exec = ''
        set -euo pipefail
        dprint check
        nixfmt --check devenv.nix
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --all -- --check
        ${resolveFlutterSdk}
        mapfile -t dart_files < <(
          git ls-files --cached --others --exclude-standard '*.dart' |
            while IFS= read -r dart_file; do
              if [ -f "$dart_file" ]; then
                printf '%s\n' "$dart_file"
              fi
            done
        )
        if [ "''${#dart_files[@]}" -gt 0 ]; then
          # Every package's analysis_options.yaml sets this, but they include
          # package: options that resolve only after `pub get`; without them
          # dart format falls back to its default and flags 283 files.
          "$flutter_sdk/bin/dart" format --trailing-commas=preserve --output none \
            --set-exit-if-changed "''${dart_files[@]}"
        fi
      '';
      description = "Check project formatting with the pinned toolchains.";
      binary = "bash";
      packages = [
        pkgs.dprint
        pkgs.nixfmt
        rustToolchain
        config.scripts.dart.scriptPackage
      ];
    };
    "lint:native" = {
      exec = ''
        set -e
        mapfile -t kotlin_files < <(find "$DEVENV_ROOT/${appDir}/android" \( -name '*.kt' -o -name '*.kts' \) -type f | sort)
        if [ "''${#kotlin_files[@]}" -gt 0 ]; then
          ktlint "''${kotlin_files[@]}"
        fi
        if command -v swiftlint >/dev/null 2>&1 && [ -d "$DEVENV_ROOT/${appDir}/ios/Runner" ]; then
          # SwiftLint needs sourcekitd from a full Xcode install.
          if xcode-select -p 2>/dev/null | grep -q CommandLineTools; then
            echo "Skipping swiftlint (requires full Xcode for sourcekitd; Command Line Tools only)."
          else
            swiftlint lint --strict "$DEVENV_ROOT/${appDir}/ios/Runner"
          fi
        else
          echo "Skipping swiftlint (not available on this platform)."
        fi
      '';
      description = "Run native Android and iOS linters.";
      binary = "bash";
      packages = [ pkgs.ktlint ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.swiftlint ];
    };
    "fix:all" = {
      exec = ''
        set -e
        fix:format
      '';
      description = "Fix all autofixable issues.";
      binary = "bash";
    };
    "fix:format" = {
      exec = ''
        set -e
        dprint fmt --config "$DEVENV_ROOT/dprint.json"
        nixfmt devenv.nix
        RUSTFMT=${rustToolchain}/bin/rustfmt \
          ${rustToolchain}/bin/cargo fmt --all
        dart format --trailing-commas=preserve .
      '';
      description = "Format project files.";
      binary = "bash";
    };
    "runner:serverpod" = {
      exec = ''
        set -euo pipefail
        ${resolveFlutterSdk}
        # The Serverpod CLI shells out to `dart`; resolve generation against
        # the Dart the app compiles with.
        export PATH="$flutter_sdk/bin:$PATH"
        cd "$DEVENV_ROOT/${serverDir}"
        serverpod generate
        # Reformat the generated trees with the pinned toolchain so generation
        # and the format gate cannot disagree.
        cd "$DEVENV_ROOT"
        mapfile -t dart_files < <(
          git ls-files --cached --others --exclude-standard \
            'verily_client/lib/*.dart' 'verily_client/lib/**/*.dart' \
            'verily_server/lib/*.dart' 'verily_server/lib/**/*.dart' \
            'verily_server/test/*.dart' 'verily_server/test/**/*.dart' |
            while IFS= read -r dart_file; do
              if [ -f "$dart_file" ]; then
                printf '%s\n' "$dart_file"
              fi
            done
        )
        if [ "''${#dart_files[@]}" -gt 0 ]; then
          "$flutter_sdk/bin/dart" format "''${dart_files[@]}"
        fi
      '';
      description = "Run Serverpod code generation with the project-matched Nix CLI.";
      binary = "bash";
    };
    "render:promo" = {
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT/packages/verily_brand"
        dart run tool/render_promo.dart "$@"
      '';
      description = "Render Verily's launch promo reel and cover image to .screenshots/promo.";
      binary = "bash";
      packages = [
        config.scripts.dart.scriptPackage
        config.scripts.flutter.scriptPackage
        pkgs.ffmpeg
      ];
    };
    "clean:all" = {
      exec = ''
        set -e
        flutter clean
      '';
      description = "Clean Flutter build artifacts.";
      binary = "bash";
    };
  };
}
