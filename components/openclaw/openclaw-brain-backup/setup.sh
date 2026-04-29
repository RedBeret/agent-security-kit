#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-brain-backup setup"
echo "─────────────────────────"

mkdir -p "$OPENCLAW_HOME/backups"
cp "$SCRIPT_DIR/backup-brain.sh" "$OPENCLAW_HOME/backup-brain.sh"
chmod +x "$OPENCLAW_HOME/backup-brain.sh"
echo "✓ Installed backup-brain.sh"

echo ""
echo "Usage: bash ~/.openclaw/backup-brain.sh"
echo "Backups saved to: ~/.openclaw/backups/ (keeps last 5)"
