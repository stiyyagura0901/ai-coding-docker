#!/bin/bash
# Claude Code Docker Helper Script
# Manages session persistence and container lifecycle using Docker Compose

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SCRIPT_DIR}/.claude-sessions"

# Change to script directory for docker compose
cd "$SCRIPT_DIR"

# Ensure sessions directory exists
mkdir -p "$SESSIONS_DIR"

show_help() {
    echo "Claude Code Docker Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build                 Build the Docker image"
    echo "  run <prompt>          Run claude with a prompt (print mode)"
    echo "  shell                 Start an interactive shell in the container"
    echo "  list                  List available sessions"
    echo "  continue [prompt]     Continue most recent session"
    echo "  resume [id] [prompt]  Resume a specific session"
    echo "  down                  Stop and remove containers"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run 'explain this codebase'"
    echo "  $0 list"
    echo "  $0 continue 'what were we working on?'"
    echo "  $0 resume abc123 'continue the task'"
    echo "  $0 shell"
}

build_image() {
    echo "Building Docker image..."
    docker compose build
    echo "Done!"
}

run_prompt() {
    local prompt="$1"
    if [ -z "$prompt" ]; then
        echo "Error: Please provide a prompt"
        echo "Usage: $0 run 'your prompt here'"
        exit 1
    fi
    
    docker compose run --rm claude-prompt "$prompt"
}

start_shell() {
    echo "Starting interactive shell..."
    echo "Inside the container, you can run:"
    echo "  claude --dangerously-skip-permissions -p 'your prompt'"
    echo "  claude --dangerously-skip-permissions -c -p 'prompt'  # continue session"
    echo ""
    
    docker compose run --rm claude
}

list_sessions() {
    echo "Available Claude sessions:"
    echo "=========================="
    
    if [ ! -d "$SESSIONS_DIR/projects" ]; then
        echo "No sessions found. Run a prompt first to create sessions."
        return
    fi
    
    # Find all session files and extract session IDs
    find "$SESSIONS_DIR/projects" -name "*.jsonl" -type f 2>/dev/null | while read -r file; do
        filename=$(basename "$file" .jsonl)
        # Check if it looks like a UUID
        if [[ "$filename" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat --format="%y" "$file" 2>/dev/null | cut -d'.' -f1)
            echo "  $filename"
            echo "    Modified: $mod_time"
            echo ""
        fi
    done
    
    echo ""
    echo "To continue most recent session:"
    echo "  $0 continue 'your prompt'"
    echo ""
    echo "To resume a specific session:"
    echo "  $0 resume <session-id> 'your prompt'"
}

continue_session() {
    local prompt="${1:-continue from where we left off}"
    echo "Continuing most recent session..."
    echo "Prompt: $prompt"
    docker compose run --rm claude sh -c "claude --dangerously-skip-permissions -c -p '$prompt'"
}

resume_session() {
    local session_id="$1"
    local prompt="$2"
    
    if [ -z "$prompt" ]; then
        prompt="continue from where we left off"
    fi
    
    if [ -z "$session_id" ]; then
        # Continue most recent session using -c flag
        continue_session "$prompt"
    else
        # Resume specific session
        echo "Resuming session: $session_id"
        echo "Prompt: $prompt"
        docker compose run --rm claude sh -c "claude --dangerously-skip-permissions -r '$session_id' -p '$prompt'"
    fi
}

stop_containers() {
    echo "Stopping containers..."
    docker compose down
    echo "Done!"
}

# Main command handler
case "${1:-help}" in
    build)
        build_image
        ;;
    run)
        shift
        run_prompt "$*"
        ;;
    shell)
        start_shell
        ;;
    list)
        list_sessions
        ;;
    continue|c)
        continue_session "$2"
        ;;
    resume)
        resume_session "$2" "$3"
        ;;
    down|stop)
        stop_containers
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

