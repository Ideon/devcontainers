# Devcontainers

Docker images and devcontainer templates for consistent development environments
across Node.js / pnpm projects.

## Images

Published to `ghcr.io/ideon/devcontainers/` on every merge to `main`.

| Image | Description |
|---|---|
| [`node-pnpm`](images/node-pnpm/) | Node 26 + corepack + GitHub CLI + Claude Code CLI |

## Templates

Drop-in `.devcontainer/` scaffolding for common project types.

| Template | Description |
|---|---|
| [`vite-react-pnpm`](templates/vite-react-pnpm/) | Vite + React + TypeScript + pnpm |

## Design principles

- **node_modules off FUSE.** All templates keep `node_modules` and the pnpm store
  on a named Docker volume (native filesystem), not on the OrbStack FUSE bind mount.
  This prevents `zed-remote-server` CPU runaway. See the template README for details.

- **Auth via host bind-mounts, not secrets.** `~/.claude` and `~/.config/gh` are
  bind-mounted from the host — authenticate once, every container picks it up across
  rebuilds and projects.

- **Static API keys via `local.env`.** A gitignored `.devcontainer/local.env` file
  is loaded by Docker Compose (`required: false`). A template with all standard
  variable names is included but never committed with values.

- **Tooling baked into the image.** `corepack`, `gh`, and `claude-code` are in the
  image so `postCreateCommand` time is spent on project setup, not tool installation.

- **pnpm version per-project.** The image provides `corepack`; each project pins
  its own pnpm version via `package.json#packageManager`. No conflicts.

## Adding a new image

1. Create `images/<name>/Dockerfile`.
2. Add `<name>` to the matrix in `.github/workflows/publish.yml`.
3. Push to `main` — GitHub Actions builds and publishes automatically.
