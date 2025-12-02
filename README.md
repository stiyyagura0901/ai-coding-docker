# AI Coding Assistants Docker

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenCode](https://opencode.ai) CLI in Docker containers with session persistence.

## Setup

1. Copy `.env.example` to `.env` and add your API keys:
   ```bash
   cp .env.example .env
   # Edit .env and add your keys
   ```

2. Build the image:
   ```bash
   ./ai-code.sh build
   ```

## Usage

### Claude Code

```bash
# Run a prompt
./ai-code.sh claude run "explain this codebase"

# Start interactive shell
./ai-code.sh claude shell

# List saved sessions
./ai-code.sh claude list

# Continue most recent session
./ai-code.sh claude continue "what were we working on?"

# Resume specific session
./ai-code.sh claude resume <session-id> "continue the task"
```

### OpenCode

```bash
# Run a prompt
./ai-code.sh opencode run "fix the bug in main.py"

# Start interactive shell
./ai-code.sh opencode shell

# List saved sessions
./ai-code.sh opencode list

# Continue most recent session
./ai-code.sh opencode continue "what's next?"
```

### General

```bash
# Build image
./ai-code.sh build

# Stop containers
./ai-code.sh down
```

## How it works

- Claude sessions persist in `.claude-sessions/`
- OpenCode sessions persist in `.opencode-sessions/`
- Container runs as non-root user for security
- Current directory mounted to `/app` in container

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key (for Claude Code) |
| `OPENAI_API_KEY` | OpenAI API key (for OpenCode with OpenAI models) |

## License

MIT
