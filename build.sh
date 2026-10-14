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
CACHE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/hugo-cache.XXXXXX")"
trap 'rm -rf "$BUILD_TMP" "$CACHE_TMP"' EXIT

echo "==> Building site from ${REPO_DIR} into ${BUILD_TMP}"

if [[ -n "${HUGO_BIN:-}" ]]; then
  HUGO_CACHEDIR="$CACHE_TMP" "$HUGO_BIN" --source "$REPO_DIR" --destination "$BUILD_TMP" --gc --minify
else
  # --user matches whoever's running this script, so the container can
  # write into the two mounted temp dirs. HUGO_CACHEDIR redirects all of
  # Hugo's caches (used by --gc) to its own mount rather than the image's
  # baked-in /cache, which is only writable by its default uid (1000) --
  # --user above generally won't match that. (The --cacheDir CLI flag
  # does *not* cover every cache kind -- e.g. "getresource" ignores it --
  # so this has to be the env var.) Using a separate mount (not nested
  # under /dist) also keeps cache files out of the rsync below.
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HUGO_CACHEDIR=/hugo-cache \
    -v "${REPO_DIR}:/src" \
    -v "${BUILD_TMP}:/dist" \
    -v "${CACHE_TMP}:/hugo-cache" \
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
