#!/usr/bin/env bash
# Run this module on your machine, inside a real build of core.
#
#   scripts/dev.sh --core <checkout of app-agent-io/core> --platform <checkout of ulmero/platform>
#   scripts/dev.sh --core ... --platform ... --down      stop it and delete its data
#
# It does what a customer build does, with the same composer and the same
# Dockerfile: builds the three images a core release ships from your core
# checkout, composes this module in (the composer checks it against module
# format 1 and stops if it breaks a rule), builds the api and the admin, runs
# the build's smoke test, and starts the app. Your uncommitted changes are
# included. Everything runs in Docker on this machine; nothing is pushed.
#
# The first run builds core and takes several minutes. After that a change to
# the module is about two minutes: this is a build, not hot reload. The data
# stays between runs, so a change to schema.sql or a migration is tried on the
# data the previous run left, as it would be on a customer's.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
CORE=""
PLATFORM=""
VERSION="0.5.0-dev"
PORT="18090"
DOWN=""
SMOKE="yes"
while [ $# -gt 0 ]; do
  case "$1" in
    --core) CORE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --no-smoke) SMOKE=""; shift ;;
    --down) DOWN="yes"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$CORE" ] && [ -n "$PLATFORM" ] || {
  echo "usage: scripts/dev.sh --core <core checkout> --platform <ulmero/platform checkout> [--version <x.y.z>] [--port <n>] [--no-smoke] [--down]" >&2
  exit 2
}
CORE="$(cd "$CORE" && pwd)"
COMPOSER="$(cd "$PLATFORM/packages/composer" && pwd)"
for file in compose.mjs Dockerfile smoke.sh; do
  [ -f "$COMPOSER/$file" ] || { echo "$COMPOSER/$file is missing: is --platform a checkout of ulmero/platform?" >&2; exit 1; }
done
[ -f "$CORE/docker/builder.Dockerfile" ] || { echo "$CORE has no docker/builder.Dockerfile: is --core a checkout of core?" >&2; exit 1; }

field() { node -e 'const m = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8")); console.log(m[process.argv[2]] ?? "")' "$HERE/module.json" "$1"; }
NAMESPACE="$(field namespace)"
SLUG="$(field slug)"
[ -n "$NAMESPACE" ] && [ -n "$SLUG" ] || { echo "module.json needs a namespace and a slug" >&2; exit 1; }
PROJECT="moddev-$NAMESPACE-$SLUG"
compose() { API_IMAGE="$PROJECT/api" ADMIN_IMAGE="$PROJECT/admin" EDGE_PORT="$PORT" docker compose -p "$PROJECT" -f "$CORE/compose.e2e.yml" "$@"; }

if [ -n "$DOWN" ]; then
  compose down -v
  echo "stopped, and its data is deleted"
  exit 0
fi

step() { printf '\n== %s\n' "$*"; }

step "1. the three images a core release ships, from $CORE at $(git -C "$CORE" rev-parse --short HEAD)"
docker build -q -f "$CORE/docker/builder.Dockerfile" --build-arg APP_VERSION="$VERSION" -t moddev/builder "$CORE" > /dev/null
docker build -q -f "$CORE/docker/api.Dockerfile" --build-arg APP_VERSION="$VERSION" -t moddev/core-api "$CORE" > /dev/null
docker build -q -f "$CORE/docker/admin.Dockerfile" --build-arg APP_VERSION="$VERSION" -t moddev/core-admin "$CORE" > /dev/null
echo "  core $VERSION"

step "2. this module, as it is on disk, into a build context"
CTX="$(mktemp -d)"
trap 'rm -rf "$CTX"' EXIT
cp "$COMPOSER/compose.mjs" "$COMPOSER/Dockerfile" "$CTX/"
DEST="$CTX/modules/$NAMESPACE/$SLUG"
mkdir -p "$DEST"
# The places module format 1 names, and nothing else of this repository.
for path in module.json schema.sql README.md tests api admin; do
  [ -e "$HERE/$path" ] && cp -R "$HERE/$path" "$DEST/"
done
# What a build on this machine may have left behind, and what the composer writes itself.
find "$DEST" \( -name node_modules -o -name .nuxt -o -name .output \) -prune -exec rm -rf {} +
rm -f "$DEST/api/nuxt.config.ts" "$DEST/api/package.json" "$DEST/admin/nuxt.config.ts" \
  "$DEST/admin/package.json" "$DEST/admin/app/app.config.ts" "$DEST/admin/i18n/i18n.config.ts"
(cd "$DEST" && find . -type f | sed 's|^\./|  |' | sort)

step "3. compose and build: the composer checks the module first"
args=(--build-arg BUILDER=moddev/builder --build-arg CORE_API=moddev/core-api
  --build-arg CORE_ADMIN=moddev/core-admin --build-arg "BUILD_ID=$VERSION-dev")
docker build --target api "${args[@]}" -t "$PROJECT/api" "$CTX"
docker build --target admin "${args[@]}" -t "$PROJECT/admin" "$CTX"

if [ -n "$SMOKE" ]; then
  step "4. the build's smoke test, with no network"
  "$COMPOSER/smoke.sh" "$PROJECT/api"
fi

step "5. start it"
compose up -d --wait
echo
echo "  the app:  http://localhost:$PORT"
seed="$(compose logs api 2>&1 | grep -o 'Created first admin [^ ]* / [^ ]*' | head -1 || true)"
if [ -n "$seed" ]; then
  echo "  sign in:  $(echo "$seed" | awk '{print $4}') / $(echo "$seed" | awk '{print $6}')"
else
  echo "  sign in:  as the first admin. Core prints its password once, on an empty database:"
  echo "            scripts/dev.sh ... --down, then run again, to start from an empty one"
fi
echo "  the page: http://localhost:$PORT/$NAMESPACE/$SLUG/"
echo "  logs:     API_IMAGE=x ADMIN_IMAGE=y docker compose -p $PROJECT -f $CORE/compose.e2e.yml logs -f api"
echo "  stop:     scripts/dev.sh --core $CORE --platform $PLATFORM --down"
