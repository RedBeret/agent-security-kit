#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-publish-gate setup"
echo "─────────────────────────"

cp "$SCRIPT_DIR/publish-gate.sh" "$HERMES_HOME/publish-gate.sh"
chmod +x "$HERMES_HOME/publish-gate.sh"
echo "✓ Installed publish-gate.sh"

mkdir -p "$HERMES_HOME/skills/publish-gate"
cp "$SCRIPT_DIR/publish-gate/SKILL.md" "$HERMES_HOME/skills/publish-gate/SKILL.md"
echo "✓ Installed publish-gate skill"

echo ""
echo "Usage: bash ~/.hermes/publish-gate.sh /path/to/repo"
