# Build from the repository root:
#   docker build -f verily_server/Dockerfile -t verily-server .
#
# The MediaPipe runtime behind the replay of local checks is published for
# Linux x64 (and macOS arm64) only, so every stage is pinned to linux/amd64;
# Apple Silicon hosts build and run the image under emulation.
#
# Build stage. Only the server, the workspace packages it depends on, the
# lockfile, and the Monosecret manifest are copied, so the image never needs
# a Flutter SDK.
FROM --platform=linux/amd64 dart:3.13.7 AS build
WORKDIR /workspace
COPY monosecret.toml pubspec.lock ./
COPY packages/verily_escrow_client packages/verily_escrow_client
COPY packages/verily_evidence packages/verily_evidence
COPY verily_server verily_server
# A server-only workspace. pub keeps the committed lockfile's versions and
# drops the Flutter packages this subset does not use.
RUN printf 'name: _\npublish_to: none\nenvironment:\n  sdk: "^3.13.0"\nworkspace:\n  - verily_server\n  - packages/verily_escrow_client\n  - packages/verily_evidence\n' > pubspec.yaml
RUN dart pub get
WORKDIR /workspace/verily_server
# Serverpod 4 uses native build hooks that `dart compile` does not support.
# `dart build cli` produces a bundle (executable plus its native libraries).
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server
# The MediaPipe replay suite, compiled against the same native assets for the
# local-check-replay stage. It never ships in the production image.
RUN dart build cli \
    --target test/unit/action_verification/local_check/mp_local_check_replayer_test.dart \
    --output build/local-check-replay

# Runtime. Monosecret's native Dart SDK supports glibc Linux, not musl, so the
# slim Debian runtime keeps the bundle and system glibc on one ABI. The
# bundled libraries need glibc 2.39 (Monosecret) and the libstdc++ of GCC 13
# or newer (MediaPipe and OpenCV); trixie has glibc 2.41 and GCC 14's.
FROM --platform=linux/amd64 debian:trixie-slim AS runtime

# ffmpeg decodes pinned evidence into frames and PCM for the MediaPipe
# replay of local checks; libstdc++6 is what the bundled MediaPipe and OpenCV
# libraries (fetched for linux-x64 by mp_core's build hook) link against.
# Without either, the replay reports itself unavailable and the AI policy or
# a person decides instead.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
       ffmpeg libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Debian links /bin into /usr/bin; keep the bundle in its own directory so its
# bin/server cannot shadow the system shell.
WORKDIR /app

COPY --from=build /workspace/verily_server/build/bundle/ ./
COPY --from=build /workspace/verily_server/config/ config/
COPY --from=build /workspace/monosecret.toml monosecret.toml
# A deployment stage may add the Flutter web build at web/app.
RUN mkdir -p web
COPY --from=build /workspace/verily_server/migrations/ migrations/
COPY --from=build /workspace/verily_server/docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# Required for the endpoint log filter in Insights.
COPY --from=build /workspace/verily_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# The pinned local-check models, baked in so the replay never fetches at
# runtime. Each file is named by its SHA-256 and checked here; the server
# checks it again on every load. Keep in sync with local_check_catalog.dart
# (a unit test compares them).
RUN mkdir -p /app/local-check-models \
    && cd /app/local-check-models \
    && curl --fail --silent --show-error --location \
       --output 97952348cf6a6a4915c2ea1496b4b37ebabc50cbbf80571435643c455f2b0482 \
       https://storage.googleapis.com/mediapipe-models/gesture_recognizer/gesture_recognizer/float16/1/gesture_recognizer.task \
    && curl --fail --silent --show-error --location \
       --output 0720bf247bd76e6594ea28fa9c6f7c5242be774818997dbbeffc4da460c723bb \
       https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/int8/1/efficientdet_lite0.tflite \
    && curl --fail --silent --show-error --location \
       --output 4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf \
       https://storage.googleapis.com/mediapipe-models/audio_classifier/yamnet/float32/1/yamnet.tflite \
    && for file in *; do echo "$file  $file" | sha256sum --check --strict -; done
ENV VERILY_LOCAL_CHECK_MODEL_CACHE=/app/local-check-models

# The replay suite on exactly the production runtime: the bundled MediaPipe
# and OpenCV libraries, ffmpeg, and the baked models, replaying public
# fixtures it downloads and checks by SHA-256. Local CI's test:server-image
# lane runs it (docs/local-ci.md); deployments build the default target.
FROM runtime AS local-check-replay
ENV VERILY_LOCAL_CHECK_REPLAY_REQUIRED=true
COPY --from=build /workspace/verily_server/build/local-check-replay/bundle/bin/mp_local_check_replayer_test bin/local-check-replay
ENTRYPOINT ["./bin/local-check-replay"]

# Production, the default target.
FROM runtime AS production

EXPOSE 8180
EXPOSE 8181
EXPOSE 8182

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=4 \
    CMD curl --fail --silent --show-error http://127.0.0.1:8182/healthz >/dev/null

# Production processes read secrets from the injected environment only.
# Apply migrations from the release command with VERILY_APPLY_MIGRATIONS=true.
ENTRYPOINT ["./docker-entrypoint.sh"]
