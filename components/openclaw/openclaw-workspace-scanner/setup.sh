#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-workspace-scanner setup"
echo "──────────────────────────────"

cp "$SCRIPT_DIR/scan-workspace.sh" "$OPENCLAW_HOME/scan-workspace.sh"
chmod +x "$OPENCLAW_HOME/scan-workspace.sh"
echo "✓ Installed scan-workspace.sh"

echo ""
echo "Usage: bash ~/.openclaw/scan-workspace.sh [directory]"
echo "Default scans: ~/.openclaw/"
