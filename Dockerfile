# AI Coding Assistants Docker Container
# Runs Claude Code and OpenCode CLI in a containerized environment with session persistence

# Use Debian-based Node image for better compatibility with OpenCode binaries
FROM node:22-slim

# Install dependencies needed for OpenCode
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install both Claude Code and OpenCode CLI globally
RUN npm install -g @anthropic-ai/claude-code opencode-ai

# Create non-root user for security (required for --dangerously-skip-permissions)
RUN useradd -m -d /home/coder -s /bin/bash coder

# Create directories for session persistence
RUN mkdir -p /home/coder/.claude /home/coder/.local/share/opencode && \
    chown -R coder:coder /home/coder/.claude /home/coder/.local

USER coder

# Set working directory
WORKDIR /app

# Default command
CMD ["bash"]
