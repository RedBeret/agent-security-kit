#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-context-guard setup"
echo "──────────────────────────"

mkdir -p "$OPENCLAW_HOME/skills/context-guard"
cp "$SCRIPT_DIR/context-guard/SKILL.md" "$OPENCLAW_HOME/skills/context-guard/SKILL.md"
echo "✓ Installed context-guard skill"

echo ""
echo "Done! The agent will use context-guard in long sessions."
echo ""
echo "Alternative: point external_dirs in openclaw.json:"
echo "  skills:"
echo "    external_dirs:"
echo "      - $SCRIPT_DIR"
