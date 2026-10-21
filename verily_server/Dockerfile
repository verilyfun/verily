# Build from the repository root:
#   docker build -f verily_server/Dockerfile -t verily-server .
#
# Build stage. Only the server, its shared evidence package, and the
# Monosecret manifest are copied, so the image never needs a Flutter SDK.
FROM dart:3.13.5 AS build
WORKDIR /workspace
COPY monosecret.toml monosecret.toml
COPY packages/verily_evidence packages/verily_evidence
COPY verily_server verily_server
RUN printf 'name: _\npublish_to: none\nenvironment:\n  sdk: "^3.13.0"\nworkspace:\n  - verily_server\n  - packages/verily_evidence\n' > pubspec.yaml
RUN dart pub get
WORKDIR /workspace/verily_server
# Serverpod 4 uses native build hooks that `dart compile` does not support.
# `dart build cli` produces a bundle (executable plus its native libraries).
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server

# Runtime. Monosecret's native Dart SDK supports glibc Linux, not musl, so the
# slim Debian runtime keeps the bundle and system glibc on one ABI.
FROM debian:trixie-slim AS production

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
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

EXPOSE 8180
EXPOSE 8181
EXPOSE 8182

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=4 \
    CMD curl --fail --silent --show-error http://127.0.0.1:8182/healthz >/dev/null

# Production processes read secrets from the injected environment only.
# Apply migrations from the release command with VERILY_APPLY_MIGRATIONS=true.
ENTRYPOINT ["./docker-entrypoint.sh"]
