#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-commit-guard setup"
echo "─────────────────────────"

# Install hook
mkdir -p "$HERMES_HOME/agent-hooks"
cp "$SCRIPT_DIR/inject-commit-policy.sh" "$HERMES_HOME/agent-hooks/inject-commit-policy.sh"
chmod +x "$HERMES_HOME/agent-hooks/inject-commit-policy.sh"
echo "✓ Installed inject-commit-policy.sh hook"

cp "$SCRIPT_DIR/block-ai-attribution.sh" "$HERMES_HOME/agent-hooks/block-ai-attribution.sh"
chmod +x "$HERMES_HOME/agent-hooks/block-ai-attribution.sh"
echo "✓ Installed block-ai-attribution.sh helper"

# Install skill
mkdir -p "$HERMES_HOME/skills/commit-guard"
cp "$SCRIPT_DIR/commit-guard/SKILL.md" "$HERMES_HOME/skills/commit-guard/SKILL.md"
echo "✓ Installed commit-guard skill"

echo ""
echo "Add to ~/.hermes/config.yaml:"
echo ""
echo "hooks:"
echo "  pre_llm_call:"
echo "    - command: \"~/.hermes/agent-hooks/inject-commit-policy.sh\""
echo "      timeout: 3"
echo ""
echo "Optional git hook for each repo:"
echo "  cp ~/.hermes/agent-hooks/block-ai-attribution.sh .git/hooks/commit-msg"
