#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-egress-guard setup"
echo "─────────────────────────"

command -v jq >/dev/null 2>&1 && echo "✓ jq found" || { echo "✗ jq required: brew install jq / apt install jq"; exit 1; }

mkdir -p "$HERMES_HOME/agent-hooks"
cp "$SCRIPT_DIR/block-secrets.sh" "$HERMES_HOME/agent-hooks/block-secrets.sh"
chmod +x "$HERMES_HOME/agent-hooks/block-secrets.sh"
echo "✓ Installed block-secrets.sh"

echo ""
echo "Add to ~/.hermes/config.yaml:"
echo ""
echo "hooks:"
echo "  pre_tool_call:"
echo "    - matcher: \"terminal|write_file|patch\""
echo "      command: \"~/.hermes/agent-hooks/block-secrets.sh\""
echo "      timeout: 5"
