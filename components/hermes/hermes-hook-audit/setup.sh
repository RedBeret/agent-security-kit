#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-hook-audit setup"
echo "-----------------------"

command -v jq >/dev/null 2>&1 && echo "jq found" || { echo "jq required: brew install jq / apt install jq"; exit 1; }

mkdir -p "$HERMES_HOME/agent-hooks" "$HERMES_HOME/logs"
cp "$SCRIPT_DIR/audit-hook.sh" "$HERMES_HOME/agent-hooks/audit-hook.sh"
chmod +x "$HERMES_HOME/agent-hooks/audit-hook.sh"

echo "Installed audit-hook.sh to $HERMES_HOME/agent-hooks/"
echo ""
echo "Add to ~/.hermes/config.yaml:"
echo ""
echo "hooks:"
echo "  pre_tool_call:"
echo "    - command: \"~/.hermes/agent-hooks/audit-hook.sh\""
echo "      timeout: 5"
echo "  post_tool_call:"
echo "    - command: \"~/.hermes/agent-hooks/audit-hook.sh\""
echo "      timeout: 5"
