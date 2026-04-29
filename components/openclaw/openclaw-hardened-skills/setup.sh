#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-hardened-skills setup"
echo "────────────────────────────"

mkdir -p "$OPENCLAW_HOME/skills"

for skill in cybersecurity-advisor aws-architect fullstack-developer project-planner; do
  src="$SCRIPT_DIR/skills/$skill"
  dst="$OPENCLAW_HOME/skills/$skill"
  if [ -f "$src/SKILL.md" ]; then
    mkdir -p "$dst"
    cp "$src/SKILL.md" "$dst/SKILL.md"
    echo "✓ Installed $skill"
  fi
done

echo ""
echo "Done! Skills are active on next OpenClaw session."
echo ""
echo "Alternative: use external_dirs in ~/.openclaw/openclaw.json:"
echo "  skills:"
echo "    external_dirs:"
echo "      - $SCRIPT_DIR/skills"
