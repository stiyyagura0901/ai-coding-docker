# Claude Code Docker

Run [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) in a Docker container with session persistence.

## Setup

1. Copy `.env.example` to `.env` and add your Anthropic API key:
   ```bash
   cp .env.example .env
   # Edit .env and add your ANTHROPIC_API_KEY
   ```

2. Build the image:
   ```bash
   ./claude.sh build
   ```

## Usage

```bash
# Run a prompt
./claude.sh run "explain this codebase"

# Start interactive shell
./claude.sh shell

# List saved sessions
./claude.sh list

# Continue most recent session
./claude.sh continue "what were we working on?"

# Resume specific session
./claude.sh resume <session-id> "continue the task"

# Stop containers
./claude.sh down
```

## How it works

- Sessions are persisted in `.claude-sessions/` directory
- The container runs as a non-root user (required for `--dangerously-skip-permissions`)
- Your current directory is mounted to `/app` in the container

## License

MIT

