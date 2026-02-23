#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration (override via environment or .env file) ---
if [ -f "$SCRIPT_DIR/.env" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/.env"
fi

MAX_TURNS="${MAX_TURNS:-15}"
LOG_DIR="${LOG_DIR:-$HOME/.claude-checkins/logs}"
SLACK_CHANNEL="${SLACK_CHANNEL:-project-checkins}"

# --- Usage ---
usage() {
    echo "Usage: $0 [project-directory]"
    echo ""
    echo "  project-directory  Path to the git repo to check in on (default: current directory)"
    echo ""
    echo "Environment variables:"
    echo "  MAX_TURNS       Max Claude turns (default: 15)"
    echo "  LOG_DIR         Log directory (default: ~/.claude-checkins/logs)"
    echo "  SLACK_CHANNEL   Slack channel name (default: project-checkins)"
    exit 1
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
fi

# --- Resolve project directory ---
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# --- Validate prerequisites ---
if ! command -v claude &>/dev/null; then
    echo "Error: 'claude' CLI not found. Install with: npm install -g @anthropic-ai/claude-code" >&2
    exit 1
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Error: '$PROJECT_DIR' is not a git repository" >&2
    exit 1
fi

# --- Set up logging ---
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
LOG_FILE="$LOG_DIR/${PROJECT_NAME}_${TIMESTAMP}.log"

# --- Build the allowed tools list ---
ALLOWED_TOOLS=(
    "Read"
    "Glob"
    "Grep"
    "Edit"
    "Write"
    "Bash(git *)"
    "Bash(npm test *)"
    "Bash(npm run *)"
    "Bash(go test *)"
    "Bash(python -m pytest *)"
    "Bash(pytest *)"
    "mcp__claude_ai_Slack__slack_send_message"
    "mcp__claude_ai_Slack__slack_search_channels"
)

# Join tools with commas
TOOLS_CSV=""
for tool in "${ALLOWED_TOOLS[@]}"; do
    if [ -z "$TOOLS_CSV" ]; then
        TOOLS_CSV="$tool"
    else
        TOOLS_CSV="$TOOLS_CSV,$tool"
    fi
done

# --- Build the prompt ---
PROMPT="Perform a daily check-in on this project. The Slack channel to post to is #${SLACK_CHANNEL}. Today's date is $(date +%Y-%m-%d)."

echo "=== Claude Check-in ===" | tee "$LOG_FILE"
echo "Project:   $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" | tee -a "$LOG_FILE"
echo "Max turns: $MAX_TURNS" | tee -a "$LOG_FILE"
echo "Log file:  $LOG_FILE" | tee -a "$LOG_FILE"
echo "=======================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# --- Run Claude in headless mode ---
claude -p "$PROMPT" \
    --max-turns "$MAX_TURNS" \
    --allowedTools "$TOOLS_CSV" \
    --append-system-prompt-file "$SCRIPT_DIR/checkin-prompt.md" \
    --output-format json \
    --cwd "$PROJECT_DIR" \
    2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$LOG_FILE"
echo "=== Check-in complete (exit code: $EXIT_CODE) ===" | tee -a "$LOG_FILE"

exit "$EXIT_CODE"
