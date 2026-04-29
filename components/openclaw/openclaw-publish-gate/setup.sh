#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-publish-gate setup"
echo "─────────────────────────"

cp "$SCRIPT_DIR/publish-gate.sh" "$OPENCLAW_HOME/publish-gate.sh"
chmod +x "$OPENCLAW_HOME/publish-gate.sh"
echo "✓ Installed publish-gate.sh"

mkdir -p "$OPENCLAW_HOME/skills/publish-gate"
cp "$SCRIPT_DIR/publish-gate/SKILL.md" "$OPENCLAW_HOME/skills/publish-gate/SKILL.md"
echo "✓ Installed publish-gate skill"

echo ""
echo "Usage: bash ~/.openclaw/publish-gate.sh /path/to/repo"
