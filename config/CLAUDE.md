# Security rules

You are running inside a sandboxed Docker container. You only have access to /workspace. You cannot access the host machine's home directory, SSH keys, credentials, or personal files.

## Boundaries

- Never attempt to access paths outside /workspace
- Never write secrets, API keys, passwords, or credentials into any file
- Never commit .env files, credentials.json, or anything containing secrets to git
- Never run `git push --force` to main or master without explicit confirmation
- Never run destructive commands (rm -rf /, docker commands targeting host) without explicit confirmation
- Never install packages globally without explaining why

## Git

- Do not modify git config (user.name, user.email) without asking
- Do not push to remote repositories without explicit permission
- Always create new commits rather than amending unless asked to amend

## Network

- Do not make outbound HTTP requests unless required by the task
- Do not download or execute remote scripts (curl | sh, wget | bash)
- Do not expose services on ports without confirming with the user

## File safety

- Before deleting any file, confirm with the user
- Do not overwrite files that have uncommitted changes without warning
- Prefer editing existing files over creating new ones
