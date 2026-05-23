FROM mcr.microsoft.com/devcontainers/typescript-node:4-24-bookworm

# Node 25+ no longer bundles corepack. Installing explicitly here ensures the
# latest version and future-proofs the image when the base moves to Node 26+.
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN npm install -g corepack@latest --force && corepack enable

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI — auth is provided via the ~/.claude host bind-mount;
# no credentials are baked into this image.
RUN npm install -g @anthropic-ai/claude-code

# Bake the init script in so consuming projects need zero extra files.
# postCreateCommand in the devcontainer metadata label below calls this path.
COPY init.sh /usr/local/share/devcontainer-init.sh
RUN chmod +x /usr/local/share/devcontainer-init.sh

# Declare the volume so Docker always puts node_modules on a real filesystem
# even if the devcontainer runtime doesn't process the metadata label below.
# Note: this creates an anonymous volume — the named + persistent variant is
# handled by the mounts in the metadata label.
VOLUME ["/home/node/node_modules"]

# Devcontainer metadata — merged with the consuming project's devcontainer.json
# by any compliant runtime (Zed, VS Code, Cursor via the devcontainer CLI).
# This is what allows consuming projects to reference just the image with no
# compose file and no extra config files.
#
# Variable substitution is performed by the devcontainer runtime at container
# creation time:
#   ${localWorkspaceFolderBasename}  — folder name of the opened project
#   ${env:HOME}                      — host user's home directory
LABEL devcontainer.metadata='[{ \
  "workspaceFolder": "/workspace", \
  "postCreateCommand": "bash /usr/local/share/devcontainer-init.sh", \
  "initializeCommand": "mkdir -p ${localWorkspaceFolder}/.devcontainer && touch ${localWorkspaceFolder}/.devcontainer/local.env", \
  "runArgs": ["--privileged", "--env-file", "${localWorkspaceFolder}/.devcontainer/local.env"], \
  "mounts": [ \
    "source=${localWorkspaceFolderBasename}-node-modules,target=/home/node/node_modules,type=volume", \
    "source=${localWorkspaceFolderBasename}-claude,target=/home/node/.claude,type=volume", \
    "source=${env:HOME}/.claude,target=/tmp/claude-host,type=bind,readonly=true", \
    "source=${env:HOME}/.config/gh,target=/home/node/.config/gh,type=bind", \
    "source=${env:HOME}/.gitconfig,target=/home/node/.gitconfig,type=bind,readonly=true", \
    "source=${env:HOME}/.netrc,target=/home/node/.netrc,type=bind,readonly=true" \
  ], \
  "customizations": { \
    "vscode": { \
      "settings": { \
        "files.watcherExclude": { \
          "**/node_modules/**": true, \
          "**/.pnpm-store/**": true \
        } \
      } \
    } \
  } \
}]'
