#!/bin/bash
# Usage: scripts/publish.sh <image-name> [--local]
#
#   <image-name>   Directory name under images/  e.g. node-pnpm
#   --local        Build and tag locally; skip push
#
# Authentication (one-time host setup):
#   brew install gh && gh auth login
#   gh auth token | docker login ghcr.io -u <github-username> --password-stdin
set -euo pipefail

REGISTRY="ghcr.io"
ORG="ideon"
REPO="devcontainers"

# ── Args ──────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 <image-name> [--local]"
  echo ""
  echo "Available images:"
  ls "$(dirname "$0")/../images/" | sed 's/^/  /'
  exit 1
}

IMAGE="${1:-}"
[ -z "$IMAGE" ] && usage

PUSH=true
[ "${2:-}" = "--local" ] && PUSH=false

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_DIR="$REPO_ROOT/images/$IMAGE"
[ -d "$IMAGE_DIR" ] || { echo "✗ images/$IMAGE not found"; usage; }

FULL_IMAGE="$REGISTRY/$ORG/$REPO/$IMAGE"

# ── Tags ──────────────────────────────────────────────────────────────────────

TAGS=("$FULL_IMAGE:latest")

if git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  SHA=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
  TAGS+=("$FULL_IMAGE:sha-$SHA")
  echo "Git SHA: $SHA"
else
  echo "Note: not a git repo — only tagging as :latest"
fi

# ── Auth check (skip if local-only) ───────────────────────────────────────────

if $PUSH; then
  LOGGED_IN=false
  DOCKER_CFG="$HOME/.docker/config.json"
  if [ -f "$DOCKER_CFG" ]; then
    # Logged in if ghcr.io appears in auths, or a credStore is configured
    # (credStore means credentials are in the OS keychain / helper)
    if python3 -c "
import json, sys
cfg = json.load(open('$DOCKER_CFG'))
if '$REGISTRY' in cfg.get('auths', {}):
    sys.exit(0)
if cfg.get('credsStore') or cfg.get('credHelpers', {}).get('$REGISTRY'):
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
      LOGGED_IN=true
    fi
  fi

  if ! $LOGGED_IN; then
    echo ""
    echo "✗ Not logged into $REGISTRY."
    echo ""
    echo "Authenticate first (one-time setup):"
    echo ""
    echo "  Option 1 — gh CLI (recommended):"
    echo "    brew install gh"
    echo "    gh auth login"
    echo "    gh auth token | docker login ghcr.io -u <github-username> --password-stdin"
    echo ""
    echo "  Option 2 — Personal Access Token:"
    echo "    Create a PAT at https://github.com/settings/tokens"
    echo "    Scopes required: read:packages, write:packages"
    echo "    docker login ghcr.io -u <github-username> -p <token>"
    echo ""
    exit 1
  fi
fi

# ── Build ─────────────────────────────────────────────────────────────────────

echo "→ Building $IMAGE"

TAG_ARGS=()
for t in "${TAGS[@]}"; do TAG_ARGS+=(-t "$t"); done

docker build "${TAG_ARGS[@]}" "$IMAGE_DIR"

echo "✓ Build complete"

# ── Push ──────────────────────────────────────────────────────────────────────

if ! $PUSH; then
  echo ""
  echo "Local build only. Tags:"
  printf "  %s\n" "${TAGS[@]}"
  exit 0
fi

echo "→ Pushing to $REGISTRY"
for t in "${TAGS[@]}"; do
  docker push "$t"
  echo "✓ $t"
done

echo ""
echo "Published:"
printf "  %s\n" "${TAGS[@]}"
