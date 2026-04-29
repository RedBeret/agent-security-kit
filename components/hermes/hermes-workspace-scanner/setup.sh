#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-workspace-scanner setup"
echo "──────────────────────────────"

cp "$SCRIPT_DIR/scan-workspace.sh" "$HERMES_HOME/scan-workspace.sh"
chmod +x "$HERMES_HOME/scan-workspace.sh"
echo "✓ Installed scan-workspace.sh"

echo ""
echo "Usage: bash ~/.hermes/scan-workspace.sh [directory]"
echo "Default scans: ~/.hermes/"
