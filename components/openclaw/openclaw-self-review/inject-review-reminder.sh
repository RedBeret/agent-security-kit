#!/usr/bin/env bash
# openclaw-self-review: pre_llm_call hook
# Injects a review reminder into every LLM turn.

cat - >/dev/null

cat <<'EOF'
{"context": "[Self-Review] Before delivering code: (1) run it, don't assume it works, (2) test with empty/bad input, (3) scan for hardcoded paths and debug statements, (4) verify all imports exist, (5) check for secrets/PII in the output."}
EOF
