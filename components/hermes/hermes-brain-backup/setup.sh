#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-brain-backup setup"
echo "─────────────────────────"

mkdir -p "$HERMES_HOME/backups"
cp "$SCRIPT_DIR/backup-brain.sh" "$HERMES_HOME/backup-brain.sh"
chmod +x "$HERMES_HOME/backup-brain.sh"
echo "✓ Installed backup-brain.sh"

echo ""
echo "Usage: bash ~/.hermes/backup-brain.sh"
echo "Backups saved to: ~/.hermes/backups/ (keeps last 5)"
