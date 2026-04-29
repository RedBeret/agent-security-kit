#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-self-review setup"
echo "────────────────────────"

mkdir -p "$HERMES_HOME/skills/self-review"
cp "$SCRIPT_DIR/self-review/SKILL.md" "$HERMES_HOME/skills/self-review/SKILL.md"
echo "✓ Installed self-review skill"

mkdir -p "$HERMES_HOME/agent-hooks"
cp "$SCRIPT_DIR/inject-review-reminder.sh" "$HERMES_HOME/agent-hooks/inject-review-reminder.sh"
chmod +x "$HERMES_HOME/agent-hooks/inject-review-reminder.sh"
echo "✓ Installed review reminder hook"

echo ""
echo "Optional: add to ~/.hermes/config.yaml:"
echo ""
echo "hooks:"
echo "  pre_llm_call:"
echo "    - command: \"~/.hermes/agent-hooks/inject-review-reminder.sh\""
echo "      timeout: 3"
