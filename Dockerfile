# AI Coding Assistants Docker Container
# Runs Claude Code and OpenCode CLI in a containerized environment with session persistence

FROM node:22-alpine

# Install both Claude Code and OpenCode CLI globally
RUN npm install -g @anthropic-ai/claude-code opencode-ai

# Create non-root user for security (required for --dangerously-skip-permissions)
RUN adduser -D -h /home/coder coder

# Create directories for session persistence
RUN mkdir -p /home/coder/.claude /home/coder/.local/share/opencode && \
    chown -R coder:coder /home/coder/.claude /home/coder/.local

USER coder

# Set working directory
WORKDIR /app

# Default command
CMD ["sh"]
