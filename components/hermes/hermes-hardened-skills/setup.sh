#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-hardened-skills setup"
echo "────────────────────────────"

mkdir -p "$HERMES_HOME/skills"

for skill in cybersecurity-advisor aws-architect fullstack-developer project-planner; do
  src="$SCRIPT_DIR/skills/$skill"
  dst="$HERMES_HOME/skills/$skill"
  if [ -f "$src/SKILL.md" ]; then
    mkdir -p "$dst"
    cp "$src/SKILL.md" "$dst/SKILL.md"
    echo "✓ Installed $skill"
  fi
done

echo ""
echo "Done! Skills are active on next Hermes session."
echo ""
echo "Alternative: use external_dirs in ~/.hermes/config.yaml:"
echo "  skills:"
echo "    external_dirs:"
echo "      - $SCRIPT_DIR/skills"
