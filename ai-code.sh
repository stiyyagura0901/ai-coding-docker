#!/bin/bash
# AI Coding Assistants Docker Helper Script
# Supports both Claude Code and OpenCode with session persistence

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SESSIONS_DIR="${SCRIPT_DIR}/.claude-sessions"
OPENCODE_SESSIONS_DIR="${SCRIPT_DIR}/.opencode-sessions"

# Change to script directory for docker compose
cd "$SCRIPT_DIR"

# Ensure sessions directories exist
mkdir -p "$CLAUDE_SESSIONS_DIR" "$OPENCODE_SESSIONS_DIR"

show_help() {
    echo "AI Coding Assistants Docker Helper"
    echo ""
    echo "Usage: $0 <assistant> <command> [options]"
    echo ""
    echo "Assistants:"
    echo "  claude              Use Claude Code"
    echo "  opencode            Use OpenCode"
    echo ""
    echo "Commands:"
    echo "  build               Build the Docker image"
    echo "  run <prompt>        Run with a prompt"
    echo "  shell               Start an interactive shell"
    echo "  list                List available sessions"
    echo "  continue [prompt]   Continue most recent session"
    echo "  resume <id> [prompt] Resume a specific session"
    echo "  down                Stop and remove containers"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 claude run 'explain this codebase'"
    echo "  $0 claude continue 'what were we working on?'"
    echo "  $0 opencode run 'fix the bug'"
    echo "  $0 opencode continue"
    echo "  $0 claude shell"
}

build_image() {
    echo "Building Docker image..."
    docker compose build
    echo "Done!"
}

# ============================================
# CLAUDE CODE FUNCTIONS
# ============================================

claude_run() {
    local prompt="$1"
    if [ -z "$prompt" ]; then
        echo "Error: Please provide a prompt"
        echo "Usage: $0 claude run 'your prompt here'"
        exit 1
    fi
    docker compose run --rm claude-prompt "$prompt"
}

claude_shell() {
    echo "Starting Claude Code shell..."
    echo "Inside the container, run:"
    echo "  claude --dangerously-skip-permissions -p 'your prompt'"
    echo "  claude --dangerously-skip-permissions -c -p 'prompt'  # continue session"
    echo ""
    docker compose run --rm claude
}

claude_list() {
    echo "Available Claude sessions:"
    echo "=========================="
    
    if [ ! -d "$CLAUDE_SESSIONS_DIR/projects" ]; then
        echo "No sessions found. Run a prompt first."
        return
    fi
    
    find "$CLAUDE_SESSIONS_DIR/projects" -name "*.jsonl" -type f 2>/dev/null | while read -r file; do
        filename=$(basename "$file" .jsonl)
        if [[ "$filename" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat --format="%y" "$file" 2>/dev/null | cut -d'.' -f1)
            echo "  $filename"
            echo "    Modified: $mod_time"
            echo ""
        fi
    done
    
    echo "To continue: $0 claude continue 'your prompt'"
}

claude_continue() {
    local prompt="${1:-continue from where we left off}"
    echo "Continuing Claude session..."
    docker compose run --rm claude sh -c "claude --dangerously-skip-permissions -c -p '$prompt'"
}

claude_resume() {
    local session_id="$1"
    local prompt="${2:-continue from where we left off}"
    
    if [ -z "$session_id" ]; then
        claude_continue "$prompt"
    else
        echo "Resuming Claude session: $session_id"
        docker compose run --rm claude sh -c "claude --dangerously-skip-permissions -r '$session_id' -p '$prompt'"
    fi
}

# ============================================
# OPENCODE FUNCTIONS
# ============================================

opencode_run() {
    local prompt="$1"
    if [ -z "$prompt" ]; then
        echo "Error: Please provide a prompt"
        echo "Usage: $0 opencode run 'your prompt here'"
        exit 1
    fi
    docker compose run --rm opencode-run "$prompt"
}

opencode_shell() {
    echo "Starting OpenCode shell..."
    echo "Inside the container, run:"
    echo "  opencode run 'your prompt'"
    echo "  opencode run -c 'prompt'  # continue session"
    echo ""
    docker compose run --rm opencode
}

opencode_list() {
    echo "Available OpenCode sessions:"
    echo "============================"
    
    if [ ! -d "$OPENCODE_SESSIONS_DIR/storage" ]; then
        echo "No sessions found. Run a prompt first."
        return
    fi
    
    # List session directories
    find "$OPENCODE_SESSIONS_DIR/storage" -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
        dirname=$(basename "$dir")
        if [ "$dirname" != "storage" ]; then
            mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$dir" 2>/dev/null || stat --format="%y" "$dir" 2>/dev/null | cut -d'.' -f1)
            echo "  $dirname"
            echo "    Modified: $mod_time"
            echo ""
        fi
    done
    
    echo "To continue: $0 opencode continue 'your prompt'"
}

opencode_continue() {
    local prompt="${1:-continue from where we left off}"
    echo "Continuing OpenCode session..."
    docker compose run --rm opencode-continue "$prompt"
}

opencode_resume() {
    local session_id="$1"
    local prompt="${2:-continue from where we left off}"
    
    if [ -z "$session_id" ]; then
        opencode_continue "$prompt"
    else
        echo "Resuming OpenCode session: $session_id"
        docker compose run --rm opencode sh -c "opencode run -s '$session_id' '$prompt'"
    fi
}

# ============================================
# MAIN COMMAND HANDLER
# ============================================

stop_containers() {
    echo "Stopping containers..."
    docker compose down
    echo "Done!"
}

# Handle build and down commands without assistant prefix
case "${1:-help}" in
    build)
        build_image
        exit 0
        ;;
    down|stop)
        stop_containers
        exit 0
        ;;
    help|--help|-h)
        show_help
        exit 0
        ;;
esac

# Handle assistant-specific commands
ASSISTANT="${1:-}"
COMMAND="${2:-}"
ARG1="${3:-}"
ARG2="${4:-}"

case "$ASSISTANT" in
    claude)
        case "$COMMAND" in
            run)
                shift 2
                claude_run "$*"
                ;;
            shell)
                claude_shell
                ;;
            list)
                claude_list
                ;;
            continue|c)
                claude_continue "$ARG1"
                ;;
            resume)
                claude_resume "$ARG1" "$ARG2"
                ;;
            *)
                echo "Unknown claude command: $COMMAND"
                show_help
                exit 1
                ;;
        esac
        ;;
    opencode)
        case "$COMMAND" in
            run)
                shift 2
                opencode_run "$*"
                ;;
            shell)
                opencode_shell
                ;;
            list)
                opencode_list
                ;;
            continue|c)
                opencode_continue "$ARG1"
                ;;
            resume)
                opencode_resume "$ARG1" "$ARG2"
                ;;
            *)
                echo "Unknown opencode command: $COMMAND"
                show_help
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown assistant: $ASSISTANT"
        show_help
        exit 1
        ;;
esac

