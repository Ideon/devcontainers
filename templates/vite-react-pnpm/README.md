# Template: `vite-react-pnpm`

Devcontainer template for Vite + React + TypeScript projects using pnpm.

## Using this template

1. Copy `.devcontainer/` into your project root.
2. Add to your project's `.gitignore`:
   ```
   .devcontainer/local.env
   ```
3. Fill in `.devcontainer/local.env` with any API keys your project needs.
4. Open the project in Zed (or VS Code / Cursor) and choose **Reopen in Container**.

That's it. All mounts, volume setup, and init are handled by the image.

## First-time host setup

One-time steps on your Mac — shared automatically across all devcontainers.

```sh
# GitHub CLI — tokens stored in ~/.config/gh, bind-mounted into every container
gh auth login

# Claude Code — OAuth token stored in ~/.claude, seeded into each project's
# isolated claude volume on first container creation
claude
```

AI API keys (`OPENAI_API_KEY` etc.) go in `.devcontainer/local.env`.

## What the image provides automatically

Everything below is embedded in the image's `devcontainer.metadata` label and
applied by the devcontainer runtime at container creation — no compose file,
no project-side config files needed.

| Concern | How it's handled |
|---|---|
| `workspaceFolder` | `/workspaces/<project-name>` |
| `node_modules` off FUSE | Named volume `<project>-node-modules` at `/home/node/node_modules` |
| pnpm store | Nested inside the `node_modules` volume as `.pnpm-store/` |
| Symlinks in workspace | `init.sh` (baked into image at `/usr/local/share/devcontainer-init.sh`) |
| Claude Code context | Named volume `<project>-claude` — isolated per project |
| Claude auth seeding | Host `~/.claude` bind-mounted read-only at `/tmp/claude-host`; credentials copied on first run of a fresh volume |
| GitHub CLI auth | Host `~/.config/gh` bind-mounted writable |
| Git identity | Host `~/.gitconfig` bind-mounted read-only |
| `local.env` loading | `initializeCommand` ensures the file exists; `runArgs --env-file` loads it |

## Volume persistence

| Volume | Scope | Persists across | Reset with |
|---|---|---|---|
| `<project>-node-modules` | Per project | Rebuilds | `docker volume rm <project>-node-modules` |
| `<project>-claude` | Per project | Rebuilds | `docker volume rm <project>-claude` |
| `~/.claude` (host) | Auth seed source | Always (host file) | Re-auth on host |
| `~/.config/gh` (host) | Shared, all projects | Always (host file) | `gh auth logout` on host |

Claude Code context (conversation memory, project summaries) accumulates in the
per-project `claude` volume and survives rebuilds. Credentials are re-seeded from
the host automatically when the volume is fresh.

## Overriding image defaults

Add properties to `devcontainer.json` — they merge with and take precedence over
the image's embedded metadata.

**Docker-in-Docker:**
```json
{
  "name": "my-project",
  "image": "ghcr.io/ideon/devcontainers/node-pnpm:latest",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
```

**Extra postCreateCommand steps:**
```json
{
  "postCreateCommand": "bash /usr/local/share/devcontainer-init.sh && pnpm run setup"
}
```

**OrbStack domain routing** — add a `runArgs` label:
```json
{
  "runArgs": [
    "--privileged",
    "--env-file", "${localWorkspaceFolder}/.devcontainer/local.env",
    "--label", "dev.orbstack.domains=myapp.local"
  ]
}
```

**Pin to a specific image version** for reproducibility:
```json
{
  "image": "ghcr.io/ideon/devcontainers/node-pnpm:sha-abc1234"
}
```

## Compose-based setup (advanced)

If your project needs multiple services (database, reverse proxy, etc.),
use a `docker-compose.yml` alongside `devcontainer.json`. Reference the
image in your compose service and set `dockerComposeFile` in `devcontainer.json`.
The `init.sh` is available at `/usr/local/share/devcontainer-init.sh` inside
the container to use as your `postCreateCommand`.
