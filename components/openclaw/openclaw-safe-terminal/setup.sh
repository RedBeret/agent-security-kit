#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-safe-terminal setup"
echo "──────────────────────────"

command -v jq >/dev/null 2>&1 && echo "✓ jq found" || { echo "✗ jq required: brew install jq / apt install jq"; exit 1; }

mkdir -p "$OPENCLAW_HOME/agent-hooks"
cp "$SCRIPT_DIR/block-destructive.sh" "$OPENCLAW_HOME/agent-hooks/block-destructive.sh"
chmod +x "$OPENCLAW_HOME/agent-hooks/block-destructive.sh"
echo "✓ Installed block-destructive.sh"

echo ""
echo "Add to ~/.openclaw/openclaw.json:"
echo ""
echo "hooks:"
echo "  pre_tool_call:"
echo "    - matcher: \"terminal\""
echo "      command: \"~/.openclaw/agent-hooks/block-destructive.sh\""
echo "      timeout: 5"
