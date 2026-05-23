# `ghcr.io/ideon/devcontainers/node-pnpm`

A devcontainer base image for Node.js + pnpm projects, built on top of
[`mcr.microsoft.com/devcontainers/typescript-node:4-24-bookworm`](https://github.com/devcontainers/images/tree/main/src/typescript-node).

## What's included (beyond the upstream image)

| Tool | Why |
|---|---|
| `corepack` (latest) | Installed explicitly to get the latest version and to be ready when base image moves to Node 26+ (which drops the bundled corepack) |
| `gh` (GitHub CLI) | Repo operations, PR workflows, auth for ghcr.io pulls inside the container |
| `@anthropic-ai/claude-code` | Claude Code CLI — credentials come from the `~/.claude` host bind-mount |

## What's NOT baked in

- **pnpm** — managed per-project via `corepack` + `package.json#packageManager`. No version conflict possible.
- **API keys / secrets** — never in the image. Provided at runtime via `local.env` and host bind-mounts.
- **Docker-in-Docker** — applied as a devcontainer feature at runtime (requires daemon setup; can't be baked).

## Tagging

| Tag | When |
|---|---|
| `latest` | Latest commit on `main` |
| `sha-<commit>` | Every merge to `main` (stable, pinnable) |

Pin to a SHA tag in `base.yml` for reproducible environments:
```yaml
image: ghcr.io/ideon/devcontainers/node-pnpm:sha-abc1234
```

## Building locally

```sh
docker build -t ghcr.io/ideon/devcontainers/node-pnpm:local .
```
