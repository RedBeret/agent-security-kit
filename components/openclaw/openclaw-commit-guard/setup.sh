#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-commit-guard setup"
echo "─────────────────────────"

# Install hook
mkdir -p "$OPENCLAW_HOME/agent-hooks"
cp "$SCRIPT_DIR/inject-commit-policy.sh" "$OPENCLAW_HOME/agent-hooks/inject-commit-policy.sh"
chmod +x "$OPENCLAW_HOME/agent-hooks/inject-commit-policy.sh"
echo "✓ Installed inject-commit-policy.sh hook"

cp "$SCRIPT_DIR/block-ai-attribution.sh" "$OPENCLAW_HOME/agent-hooks/block-ai-attribution.sh"
chmod +x "$OPENCLAW_HOME/agent-hooks/block-ai-attribution.sh"
echo "✓ Installed block-ai-attribution.sh helper"

# Install skill
mkdir -p "$OPENCLAW_HOME/skills/commit-guard"
cp "$SCRIPT_DIR/commit-guard/SKILL.md" "$OPENCLAW_HOME/skills/commit-guard/SKILL.md"
echo "✓ Installed commit-guard skill"

echo ""
echo "Add to ~/.openclaw/openclaw.json:"
echo ""
echo "hooks:"
echo "  pre_llm_call:"
echo "    - command: \"~/.openclaw/agent-hooks/inject-commit-policy.sh\""
echo "      timeout: 3"
echo ""
echo "Optional git hook for each repo:"
echo "  cp ~/.openclaw/agent-hooks/block-ai-attribution.sh .git/hooks/commit-msg"
