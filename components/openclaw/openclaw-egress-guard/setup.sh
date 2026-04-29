#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-egress-guard setup"
echo "─────────────────────────"

command -v jq >/dev/null 2>&1 && echo "✓ jq found" || { echo "✗ jq required: brew install jq / apt install jq"; exit 1; }

mkdir -p "$OPENCLAW_HOME/agent-hooks"
cp "$SCRIPT_DIR/block-secrets.sh" "$OPENCLAW_HOME/agent-hooks/block-secrets.sh"
chmod +x "$OPENCLAW_HOME/agent-hooks/block-secrets.sh"
echo "✓ Installed block-secrets.sh"

echo ""
echo "Add to ~/.openclaw/openclaw.json:"
echo ""
echo "hooks:"
echo "  pre_tool_call:"
echo "    - matcher: \"terminal|write_file|patch\""
echo "      command: \"~/.openclaw/agent-hooks/block-secrets.sh\""
echo "      timeout: 5"
