# syntax=docker/dockerfile:1
#
# Build from the repository root:
#   docker build --platform linux/amd64 -f verily_kit/Dockerfile -t verily-kit .
#
# MediaPipe's Linux native runtime is published for x86_64, so production images
# target linux/amd64. The build stage runs `leptoskit build --release --platform web`
# to produce both the `verily-kit` server binary and the optimized browser Wasm
# bundle (`dist/index.html`, `dist/pkg/`, `dist/assets/`), plus the static
# landing page (`dist/site/`).

ARG LEPTOSKIT_REV=4f52896af397cc38834ac9d937a04b02bc5c5bf4
ARG BINARYEN_VERSION=132
ARG ESBUILD_VERSION=0.27.2
ARG ESBUILD_SHA256=4ac0a36a8573ef6b612263661e7c77343a38789485344e1875cf33a498292310

FROM --platform=linux/amd64 rust:1-trixie AS build
ARG LEPTOSKIT_REV
ARG BINARYEN_VERSION
ARG ESBUILD_VERSION
ARG ESBUILD_SHA256

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install binaryen (`wasm-opt`) and checksum-verified `esbuild` matching
# LeptosKit's release web bundler.
RUN curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
      --output /tmp/binaryen.tar.gz \
      "https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz" \
    && tar -xzf /tmp/binaryen.tar.gz -C /opt \
    && rm /tmp/binaryen.tar.gz \
    && ln -s "/opt/binaryen-version_${BINARYEN_VERSION}/bin/wasm-opt" /usr/local/bin/wasm-opt \
    && curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
      --output /tmp/esbuild.tgz \
      "https://registry.npmjs.org/@esbuild/linux-x64/-/linux-x64-${ESBUILD_VERSION}.tgz" \
    && echo "${ESBUILD_SHA256}  /tmp/esbuild.tgz" | sha256sum --check --strict \
    && tar -xzf /tmp/esbuild.tgz -C /opt \
    && mv /opt/package "/opt/esbuild-${ESBUILD_VERSION}" \
    && rm /tmp/esbuild.tgz \
    && ln -s "/opt/esbuild-${ESBUILD_VERSION}/bin/esbuild" /usr/local/bin/esbuild

WORKDIR /workspace
COPY verily_kit/rust-toolchain.toml ./verily_kit/rust-toolchain.toml
RUN cd /workspace/verily_kit \
    && rustup target add wasm32-unknown-unknown \
    && cargo install --git https://github.com/leptoskit/leptoskit \
       --rev "${LEPTOSKIT_REV}" leptoskit_cli --locked --bin leptoskit

COPY monosecret.toml ./
COPY verily_kit ./verily_kit

WORKDIR /workspace/verily_kit
RUN leptoskit build --release --platform web \
    && cp target/release/verily-kit /usr/local/bin/verily-kit \
    && cargo run --release --package verily_site --locked -- /workspace/verily_kit/dist/site

FROM --platform=linux/amd64 debian:trixie-slim AS runtime

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl ffmpeg libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home app

WORKDIR /app

COPY --from=build /usr/local/bin/verily-kit /app/bin/verily-kit
COPY --from=build /workspace/verily_kit/leptoskit.toml /app/leptoskit.toml
COPY --from=build /workspace/verily_kit/monosecret.toml /app/monosecret.toml
COPY --from=build /workspace/verily_kit/dist /app/dist

# Pre-bake and SHA-256 verify the pinned MediaPipe local-check models so the
# server never downloads model weights at runtime.
RUN mkdir -p /app/local-check-models \
    && cd /app/local-check-models \
    && curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
       --output 97952348cf6a6a4915c2ea1496b4b37ebabc50cbbf80571435643c455f2b0482 \
       https://storage.googleapis.com/mediapipe-models/gesture_recognizer/gesture_recognizer/float16/1/gesture_recognizer.task \
    && curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
       --output 0720bf247bd76e6594ea28fa9c6f7c5242be774818997dbbeffc4da460c723bb \
       https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/int8/1/efficientdet_lite0.tflite \
    && curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
       --output 4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf \
       https://storage.googleapis.com/mediapipe-models/audio_classifier/yamnet/float32/1/yamnet.tflite \
    && for file in *; do echo "$file  $file" | sha256sum --check --strict -; done

ENV VERILY_BIND_ADDRESS=0.0.0.0 \
    VERILY_PORT=8184 \
    LEPTOS_ENV=PROD \
    LEPTOS_OUTPUT_NAME=verily_app \
    LEPTOS_SITE_ROOT=/app/dist \
    LEPTOS_SITE_PKG_DIR=pkg \
    VERILY_LOCAL_CHECK_MODEL_CACHE=/app/local-check-models

USER app
EXPOSE 8184

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=4 \
    CMD ["curl", "--fail", "--silent", "--output", "/dev/null", "http://127.0.0.1:8184/healthz"]

ENTRYPOINT ["/app/bin/verily-kit"]
