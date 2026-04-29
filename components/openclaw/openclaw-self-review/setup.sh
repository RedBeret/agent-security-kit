#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-self-review setup"
echo "────────────────────────"

mkdir -p "$OPENCLAW_HOME/skills/self-review"
cp "$SCRIPT_DIR/self-review/SKILL.md" "$OPENCLAW_HOME/skills/self-review/SKILL.md"
echo "✓ Installed self-review skill"

mkdir -p "$OPENCLAW_HOME/agent-hooks"
cp "$SCRIPT_DIR/inject-review-reminder.sh" "$OPENCLAW_HOME/agent-hooks/inject-review-reminder.sh"
chmod +x "$OPENCLAW_HOME/agent-hooks/inject-review-reminder.sh"
echo "✓ Installed review reminder hook"

echo ""
echo "Optional: add to ~/.openclaw/openclaw.json:"
echo ""
echo "hooks:"
echo "  pre_llm_call:"
echo "    - command: \"~/.openclaw/agent-hooks/inject-review-reminder.sh\""
echo "      timeout: 3"
