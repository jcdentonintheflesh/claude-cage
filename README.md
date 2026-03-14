# Claude Cage

Run Claude Code inside Docker so it can only access what you give it.

By default, Claude Code has access to your entire home directory: SSH keys, AWS credentials, browser profiles, dotfiles, everything. Claude Cage puts it in a container where it can only see the folders you explicitly mount.

## Why

- Claude Code runs shell commands on your machine with the permissions of your user
- It can read `~/.ssh`, `~/.aws`, `~/.config`, browser data, and anything else in your home folder
- A sandboxed container limits the blast radius to only the code you're working on
- Your credentials, keys, and personal files stay outside the container

## Setup

### 1. Create a workspace outside your home folder

This keeps your code separate from personal files. Claude only sees this folder.

```bash
sudo mkdir -p /opt/workspace
sudo chown $USER:staff /opt/workspace
```

On Linux, replace `staff` with your group (usually your username or `users`).

### 2. Build the container

```bash
git clone https://github.com/jcdentonintheflesh/claude-cage.git
cd claude-cage
docker build -t claude-cage .
```

### 3. First run

```bash
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  claude-cage
```

This starts the container in the background with two mounts:
- `/opt/workspace` is your code, shared between your machine and the container
- `claude-auth` is a Docker volume that stores your Claude login so you don't have to re-authenticate every time

### 4. Launch Claude Code

```bash
docker exec -it claude claude
```

You're now inside Claude Code, but it can only see `/opt/workspace`. Nothing else on your machine is accessible.

### 5. Daily use

```bash
docker start claude
docker exec -it claude claude
```

## What's isolated

| Accessible | Not accessible |
|---|---|
| /opt/workspace (your code) | ~/.ssh (SSH keys) |
| Claude auth (Docker volume) | ~/.aws (AWS credentials) |
| Git (inside container) | ~/.config (app configs) |
| | ~/.gnupg (GPG keys) |
| | ~/Documents, ~/Downloads |
| | Browser profiles, cookies |
| | System files, other users |

## Mounting additional folders

Need Claude to access something specific? Mount it read-only:

```bash
docker run -dit --name claude \
  -v /opt/workspace:/workspace \
  -v claude-auth:/root/.claude \
  -v ~/.gitconfig:/root/.gitconfig:ro \
  claude-cage
```

The `:ro` flag makes it read-only so Claude can read your git config but can't modify it.

## Reset everything

Remove the container and auth:

```bash
docker rm -f claude
docker volume rm claude-auth
```

Then re-run steps 3 and 4.

## Adding tools

The base image includes Git and Node.js. If your projects need Python, Docker, or other tools, edit the Dockerfile:

```dockerfile
# Add Python
RUN apt-get update && apt-get install -y python3 python3-pip --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Add any pip packages
RUN pip3 install --break-system-packages requests
```

Then rebuild: `docker build -t claude-cage .`

## Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Claude Code subscription (Pro, Max, or Team)

## License

[MIT](LICENSE)

---

Built by [@vxdenton](https://x.com/vxdenton)
