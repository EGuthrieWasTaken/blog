#!/usr/bin/env bash
#
# Build the Hugo site and atomically publish it to BLOG_PUBLIC, so nginx
# never serves a half-built site. Safe to run from cron or by hand.
#
# Env vars:
#   HUGO_BIN      - path to a local hugo binary. If unset, runs Hugo via the
#                   pinned ghcr.io/gohugoio/hugo container instead.
#   REPO_DIR      - repo checkout to build from (default: this script's dir)
#   BLOG_PUBLIC   - directory nginx serves (default: /mnt/user/appdata/blog/public)
#   HUGO_IMAGE    - override the pinned Hugo build image/tag

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_DIR}"
BLOG_PUBLIC="${BLOG_PUBLIC:-/mnt/user/appdata/blog/public}"
HUGO_IMAGE="${HUGO_IMAGE:-ghcr.io/gohugoio/hugo:v0.168.0}"

BUILD_TMP="$(mktemp -d "${TMPDIR:-/tmp}/hugo-build.XXXXXX")"
trap 'rm -rf "$BUILD_TMP"' EXIT

echo "==> Building site from ${REPO_DIR} into ${BUILD_TMP}"

if [[ -n "${HUGO_BIN:-}" ]]; then
  "$HUGO_BIN" --source "$REPO_DIR" --destination "$BUILD_TMP" --gc --minify
else
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "${REPO_DIR}:/src" \
    -v "${BUILD_TMP}:/dist" \
    -w /src \
    "$HUGO_IMAGE" \
    --destination /dist --gc --minify
fi

if [[ ! -f "${BUILD_TMP}/index.html" ]]; then
  echo "error: build did not produce ${BUILD_TMP}/index.html, aborting publish" >&2
  exit 1
fi

echo "==> Publishing to ${BLOG_PUBLIC}"
mkdir -p "$BLOG_PUBLIC"

# rsync into the live directory with --delete-after so nginx always has a
# complete tree to serve: new/changed files land before stale ones are
# removed, and there's never a window with files missing outright.
rsync -a --delete-after "${BUILD_TMP}/" "${BLOG_PUBLIC}/"

echo "==> Done"
