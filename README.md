# Claude Cage

Run Claude Code in a locked-down Docker container. It can only touch your code. Nothing else.

## The problem

Claude Code runs as your user. It executes shell commands with your permissions. That means it can read:

- **~/.ssh** - your private keys, authorized hosts, config
- **~/.aws** - access keys, secret keys, session tokens
- **~/.gnupg** - GPG private keys, trust database
- **~/.config** - app tokens, OAuth credentials, API keys stored by CLIs
- **~/.kube** - Kubernetes cluster credentials
- **~/.docker** - Docker registry auth
- **~/Documents, ~/Downloads, ~/Desktop** - personal files, tax docs, contracts, photos
- **Browser profiles** - saved passwords, cookies, session tokens, browsing history
- **Keychains and credential stores** - system-level secrets
- **Other projects** - source code, .env files, databases from every repo on your machine

Any shell command Claude runs has access to all of this. One bad prompt, one hallucinated command, or one prompt injection in a file it reads could leak sensitive data.

## The fix

Docker. Claude runs inside a container that can only see the folders you explicitly mount. Everything else on your machine is invisible.

Claude Cage gives you:

1. **Container isolation** - Claude can only access `/opt/workspace`, nothing else on your machine
2. **Security rules baked in** - a CLAUDE.md with restrictions is built into the image and loads every session
3. **Permission guardrails** - dangerous commands (rm -rf /, curl-pipe-sh, chmod 777) are blocked by default
4. **Workspace outside your home folder** - your code lives in `/opt/workspace`, not under `~`

## Setup

### 1. Create a workspace outside your home folder

```bash
sudo mkdir -p /opt/workspace
sudo chown $USER:staff /opt/workspace
```

On Linux, replace `staff` with your group (usually your username or `users`).

This is where your code lives. It's the only folder Claude can see. Keeping it outside `~` means even if something goes wrong, your personal files are untouched.

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

This builds the image with Claude Code, Git, Node.js, and the security config pre-installed.

### 4. First run

```bash
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  claude-cage
```

Two mounts:
- `/opt/workspace` is your code, shared between your machine and the container
- `claude-auth` is a Docker volume that stores your Claude login so you don't re-authenticate every time

### 5. Launch Claude Code

```bash
docker exec -it claude claude
```

That's it. You're inside Claude Code, but it can only see `/workspace`.

### 6. Daily use

```bash
docker start claude
docker exec -it claude claude
```

## What's inside the cage

The container ships with security config that loads automatically every session.

**CLAUDE.md** (baked into the image at `/workspace/CLAUDE.md`):
- Never access paths outside /workspace
- Never write secrets or credentials into files
- Never commit .env or credential files to git
- Never force-push without confirmation
- Never run destructive commands without confirmation
- Never download or execute remote scripts

**settings.json** (at `/root/.claude/settings.json`):
- File read/write/search tools are allowed
- Dangerous bash patterns are blocked: `rm -rf /`, `curl | sh`, `wget | bash`, `chmod 777`, `docker` commands

You can edit both in the `config/` folder and rebuild the image.

## What's isolated

| Inside the cage | Outside the cage |
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

The `:ro` flag means Claude can read your git config but can't change it. Only mount what you need.

## Customizing the security rules

Edit `config/CLAUDE.md` to add or relax rules. Edit `config/settings.json` to change permission defaults. Then rebuild:

```bash
docker build -t claude-cage .
docker rm -f claude
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  claude-cage
```

## Adding tools

The base image has Git and Node.js. Need more? Edit the Dockerfile:

```dockerfile
# Python
RUN apt-get update && apt-get install -y python3 python3-pip --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Go
RUN curl -fsSL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:$PATH"
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
