#!/usr/bin/env bash
set -euo pipefail

# Local CI: runs Verily's check lanes on a developer machine and posts one
# GitHub commit status per lane via `gh`, so a ruleset on `main` can require
# them. See docs/local-ci.md.
#
# Usage:
#   tool/local_ci.sh [--lane=<lane>]... [--also=<sha>]... [--no-post]

DEFAULT_LANES=(
	"lint:all"
	"test:kit"
	"test:escrow"
)
OPT_IN_LANES=(
	"test:server-image"
)
ALL_LANES=("${DEFAULT_LANES[@]}" "${OPT_IN_LANES[@]}")

NAMED_LANES=()
ALSO_SHAS=()
POST=true

usage() {
	echo "usage: tool/local_ci.sh [--lane=<lane>]... [--also=<sha>]... [--no-post]" >&2
	echo "lanes: ${ALL_LANES[*]}" >&2
	exit 64
}

lane_valid() {
	local target="$1"
	for lane in "${ALL_LANES[@]}"; do
		if [[ "$lane" == "$target" ]]; then
			return 0
		fi
	done
	return 1
}

for arg in "$@"; do
	case "$arg" in
		--lane=*)
			lane="${arg#--lane=}"
			lane_valid "$lane" || usage
			NAMED_LANES+=("$lane")
			;;
		--also=*)
			sha="${arg#--also=}"
			[[ "$sha" =~ ^[0-9a-f]{7,40}$ ]] || usage
			ALSO_SHAS+=("$sha")
			;;
		--no-post)
			POST=false
			;;
		*)
			usage
			;;
	esac
done

if [[ "${#NAMED_LANES[@]}" -gt 0 ]]; then
	RUN_LANES=("${NAMED_LANES[@]}")
else
	RUN_LANES=("${DEFAULT_LANES[@]}")
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
SHA="$(git rev-parse HEAD)"

if [[ -n "$(git status --porcelain)" ]]; then
	echo "local CI: working tree has uncommitted changes; commit first" >&2
	exit 1
fi

REPO=""
if [[ "$POST" == true ]]; then
	BRANCH="$(git rev-parse --abbrev-ref HEAD)"
	if [[ "$BRANCH" == "HEAD" || "$BRANCH" == "main" ]]; then
		echo "local CI: check out a pull request branch first, or pass --no-post" >&2
		exit 1
	fi
	REMOTE_URL="$(git remote get-url origin)"
	if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
		REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
	else
		echo "local CI: origin is not a GitHub repository; pass --no-post" >&2
		exit 1
	fi
	REMOTE_SHA="$(git ls-remote origin "refs/heads/$BRANCH" | awk '{print $1}')"
	if [[ "$REMOTE_SHA" != "$SHA" ]]; then
		echo "local CI: HEAD ($SHA) does not match origin/$BRANCH ($REMOTE_SHA); push first" >&2
		exit 1
	fi
fi

RESOLVED_ALSO=()
for sha in "${ALSO_SHAS[@]}"; do
	full="$(git rev-parse "${sha}^{commit}")"
	if ! git merge-base --is-ancestor "$full" "$SHA"; then
		echo "local CI: --also $sha is not an ancestor of HEAD" >&2
		exit 1
	fi
	RESOLVED_ALSO+=("$full")
done

COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir)"
LOCK_DIR="$COMMON_DIR/local-ci"
LOG_DIR="$LOCK_DIR/logs/$SHA"
mkdir -p "$LOG_DIR"

HOST_NAME="$(hostname -s 2>/dev/null || echo local)"

post_status() {
	local target_sha="$1"
	local context="$2"
	local state="$3"
	local desc="$4"
	if [[ "$POST" != true ]]; then
		return 0
	fi
	gh api "repos/$REPO/statuses/$target_sha" \
		-f "state=$state" \
		-f "context=$context" \
		-f "description=${desc:0:140}" >/dev/null
}

exec 9>"$LOCK_DIR/run.lock"
if ! flock -n 9; then
	echo "local CI: another local CI run holds $LOCK_DIR/run.lock" >&2
	exit 1
fi

for lane in "${RUN_LANES[@]}"; do
	post_status "$SHA" "$lane" "pending" "Running on $HOST_NAME"
done

FAILED=0
for lane in "${RUN_LANES[@]}"; do
	start_ts="$(date +%s)"
	log_file="$LOG_DIR/${lane//:/_}.log"
	if devenv shell "$lane" >"$log_file" 2>&1; then
		if [[ -n "$(git status --porcelain)" || "$(git rev-parse HEAD)" != "$SHA" ]]; then
			status="failure"
			desc="Failed locally on $HOST_NAME: lane modified working tree or HEAD"
			FAILED=1
		else
			elapsed="$(( $(date +%s) - start_ts ))s"
			status="success"
			desc="Passed locally on $HOST_NAME in $elapsed"
		fi
	else
		elapsed="$(( $(date +%s) - start_ts ))s"
		status="failure"
		desc="Failed locally on $HOST_NAME in $elapsed"
		FAILED=1
	fi
	post_status "$SHA" "$lane" "$status" "$desc"
	for anc in "${RESOLVED_ALSO[@]}"; do
		post_status "$anc" "$lane" "$status" "$desc (stack top ${SHA:0:8})"
	done
	echo "== $lane: $status ($elapsed)"
done

echo "Logs: $LOG_DIR"
exit "$FAILED"
