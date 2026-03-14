FROM node:20-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    openssh-client \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

# Security config: CLAUDE.md rules + permission settings
# These are baked into the image so they apply to every session
COPY config/CLAUDE.md /workspace/CLAUDE.md
COPY config/settings.json /root/.claude/settings.json

WORKDIR /workspace

CMD ["claude"]
