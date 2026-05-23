#!/bin/bash
set -euo pipefail

# Keep node_modules and the pnpm store off the FUSE bind mount of the workspace.
# Both must live on the same filesystem so pnpm can hardlink from the store
# into package directories — hardlinks require the same underlying device.
mkdir -p /home/node/node_modules/.pnpm-store

# workspaceFolder is /workspaces/<project> (set in the image metadata label);
# the devcontainer runtime bind-mounts the project there at container creation.
WORKSPACE="$(ls -d /workspaces/*/ 2>/dev/null | head -1)"
WORKSPACE="${WORKSPACE%/}"  # strip trailing slash

if [ -z "$WORKSPACE" ]; then
  echo "init.sh: could not locate workspace under /workspaces/" >&2
  exit 1
fi

# Replace any real directory left on the bind mount (e.g. from a previous
# host-side install) with a symlink into the Docker volume. A plain `ln -s`
# would silently nest the link inside an existing directory instead of
# replacing it, so we check and remove first.
for link in "$WORKSPACE/node_modules" "$WORKSPACE/.pnpm-store"; do
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    rm -rf "$link"
  fi
done

ln -sfn /home/node/node_modules             "$WORKSPACE/node_modules"
ln -sfn /home/node/node_modules/.pnpm-store "$WORKSPACE/.pnpm-store"

pnpm config set store-dir /home/node/node_modules/.pnpm-store

# No-op on projects without submodules.
git submodule update --init --recursive 2>/dev/null || true

# Docker volumes are created owned by root — fix before pnpm tries to write.
sudo chown -R node:node /home/node/node_modules

# Seed Claude Code credentials from the host on the first run of a fresh volume.
# Subsequent runs skip this — the volume already has credentials and any
# project-specific context Claude has written.
# Auth files only; project context (keyed by path) stays per-project.
if [ -d /tmp/claude-host ] && [ ! -f /home/node/.claude/.credentials.json ]; then
  mkdir -p /home/node/.claude
  for f in .credentials.json settings.json; do
    [ -f "/tmp/claude-host/$f" ] && cp "/tmp/claude-host/$f" "/home/node/.claude/$f"
  done
  sudo chown -R node:node /home/node/.claude
fi

pnpm install
