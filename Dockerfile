# Claude Code Docker Container
# Runs Claude Code CLI in a containerized environment with session persistence

FROM node:22-alpine

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user for security (required for --dangerously-skip-permissions)
RUN adduser -D -h /home/claude claude

# Create .claude directory for session persistence
RUN mkdir -p /home/claude/.claude && chown -R claude:claude /home/claude/.claude

USER claude

# Set working directory
WORKDIR /app

# Default command
CMD ["sh"]

