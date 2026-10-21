#!/bin/sh
set -eu

if [ "${VERILY_APPLY_MIGRATIONS:-false}" = "true" ]; then
  set -- --apply-migrations "$@"
fi

exec ./bin/server \
  "--mode=${runmode:-production}" \
  "--server-id=${serverid:-default}" \
  "--logging=${logging:-normal}" \
  "--role=${role:-monolith}" \
  "$@"
