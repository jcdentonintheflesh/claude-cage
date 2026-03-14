# Claude Cage

A Docker sandbox for Claude Code. Locks it into a single workspace folder so it can't access your SSH keys, credentials, personal files, or anything else on your machine.

## Why this exists

Claude Code runs shell commands as your user. That means it has access to:

- **~/.ssh** - private keys, authorized hosts, config
- **~/.aws** - access keys, secret keys, session tokens
- **~/.gnupg** - GPG private keys, trust database
- **~/.config** - app tokens, OAuth credentials, API keys stored by CLIs
- **~/.kube** - Kubernetes cluster credentials
- **~/.docker** - Docker registry auth
- **~/Documents, ~/Downloads, ~/Desktop** - personal files, tax docs, photos
- **Browser profiles** - saved passwords, cookies, session tokens, history
- **Keychains and credential stores** - system-level secrets
- **Other projects** - source code, .env files, databases from every repo on your machine

One bad prompt, one hallucinated command, or one prompt injection hidden in a file could touch any of this.

Claude Cage sandboxes Claude inside a Docker container where it can only see the folders you explicitly mount. Everything else is invisible.

What you get:

1. **Container isolation** - only your mounted workspace is accessible, nothing else
2. **Security rules baked in** - a CLAUDE.md with restrictions loads every session automatically
3. **Permission guardrails** - dangerous commands (`rm -rf /`, `curl | sh`, `chmod 777`) are blocked
4. **Workspace outside your home folder** - code lives in `/opt/workspace`, not under `~`

## Setup

### 1. Create a workspace outside your home folder

```bash
sudo mkdir -p /opt/workspace
sudo chown $USER:staff /opt/workspace
```

On Linux, replace `staff` with your group (usually your username or `users`).

This is the only folder Claude can see. Keeping it outside `~` means your personal files are never exposed, even if something goes wrong.

### 2. Install Docker (if you don't have it)

- **Mac/Windows:** Download [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Linux:** Follow the [official install guide](https://docs.docker.com/engine/install/)

Verify it's working: `docker --version`

### 3. Build the container

```bash
git clone https://github.com/jcdentonintheflesh/claude-cage.git
cd claude-cage
docker build -t claude-cage .
```

### 4. First run

```bash
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  claude-cage
```

Two mounts:
- `/opt/workspace` maps to `/workspace` inside the container. This is your code, shared between your machine and the sandbox.
- `claude-auth` is a Docker volume that persists your Claude login across container restarts.

### 5. Launch Claude Code

```bash
docker exec -it claude claude
```

You're in. Claude can see your workspace and nothing else.

### 6. Daily use

```bash
docker start claude
docker exec -it claude claude
```

## Security config

The container ships with security rules that load automatically every session.

**CLAUDE.md** (baked into the image at `/workspace/CLAUDE.md`):
- Never access paths outside /workspace
- Never write secrets or credentials into files
- Never commit .env or credential files to git
- Never force-push without confirmation
- Never run destructive commands without confirmation
- Never download or execute remote scripts

**settings.json** (at `/root/.claude/settings.json`):
- File read/write/search tools are allowed by default
- Dangerous bash patterns are blocked: `rm -rf /`, `curl | sh`, `wget | bash`, `chmod 777`, `docker` commands

Both files live in the `config/` folder. Edit them and rebuild the image to customize.

## What's sandboxed

| Inside the sandbox | Outside the sandbox |
|---|---|
| /opt/workspace (your code) | ~/.ssh (private keys, known hosts) |
| Claude auth (Docker volume) | ~/.aws (access keys, secret keys) |
| Git, Node.js, npm | ~/.gnupg (GPG keys) |
| Security rules (auto-loaded) | ~/.config (app tokens, OAuth creds) |
| | ~/.kube (cluster credentials) |
| | ~/.docker (registry auth) |
| | ~/Documents, ~/Downloads, ~/Desktop |
| | Browser profiles, passwords, cookies |
| | Keychains and credential stores |
| | Other projects and their .env files |
| | System files, other user accounts |

## Mounting extra folders

Need Claude to access something specific? Add it as a read-only mount:

```bash
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  -v ~/.gitconfig:/root/.gitconfig:ro \
  claude-cage
```

The `:ro` flag means Claude can read your git config but can't modify it. Only mount what you actually need.

## Adding tools

The base image has Git and Node.js. If your projects need Python or other tools, edit the Dockerfile:

```dockerfile
RUN apt-get update && apt-get install -y python3 python3-pip --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild: `docker build -t claude-cage .`

## Reset everything

```bash
docker rm -f claude
docker volume rm claude-auth
```

Then re-run steps 4 and 5.

## Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Claude Code subscription (Pro, Max, or Team)

## License

[MIT](LICENSE)

---

Built by [@vxdenton](https://x.com/vxdenton)
