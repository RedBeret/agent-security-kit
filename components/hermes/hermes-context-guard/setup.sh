#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-context-guard setup"
echo "──────────────────────────"

mkdir -p "$HERMES_HOME/skills/context-guard"
cp "$SCRIPT_DIR/context-guard/SKILL.md" "$HERMES_HOME/skills/context-guard/SKILL.md"
echo "✓ Installed context-guard skill"

echo ""
echo "Done! The agent will use context-guard in long sessions."
echo ""
echo "Alternative: point external_dirs in config.yaml:"
echo "  skills:"
echo "    external_dirs:"
echo "      - $SCRIPT_DIR"
