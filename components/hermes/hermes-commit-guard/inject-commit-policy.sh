#!/usr/bin/env bash
# hermes-commit-guard: pre_llm_call hook
# Injects commit policy into every LLM turn as context.

cat - >/dev/null   # discard stdin

cat <<'EOF'
{"context": "[Commit Policy] Never include API keys, tokens, passwords, or PII in code, commits, or files. All secrets must use the OS keystore (Keychain/secret-tool). All repos are private by default — run publish-gate before making public. No AI attribution in commits. Git identity must use the configured username, never real names. Split PRs by concern: scaffolding, models, feature, tests, docs."}
EOF
