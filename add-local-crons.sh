#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONS_DIR="$SCRIPT_DIR/local_crons"

if [ ! -d "$CRONS_DIR" ]; then
    echo "No local_crons/ directory found at $CRONS_DIR"
    exit 1
fi

# Get current crontab (empty string if none exists)
CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"

ADDED=0
SKIPPED=0

for file in "$CRONS_DIR"/*.cron; do
    [ -f "$file" ] || continue

    echo "Processing $(basename "$file")..."

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        if echo "$CURRENT_CRONTAB" | grep -qF "$line"; then
            echo "  skip (already exists): $line"
            ((SKIPPED++))
        else
            CURRENT_CRONTAB="${CURRENT_CRONTAB:+$CURRENT_CRONTAB
}$line"
            echo "  added: $line"
            ((ADDED++))
        fi
    done < "$file"
done

if [ "$ADDED" -eq 0 ]; then
    echo ""
    echo "Nothing to add. All $SKIPPED entries already in crontab."
    exit 0
fi

echo "$CURRENT_CRONTAB" | crontab -

echo ""
echo "Done. Added $ADDED, skipped $SKIPPED (already existed)."
echo ""
echo "Current crontab:"
crontab -l
