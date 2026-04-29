# Commit Guard

## Pre-Commit Rules (MANDATORY)

Before every git operation:

1. Scan staged changes: `git diff --staged | grep -iE "(sk-ant-|nvapi-|AKIA|password\s*=)"`
2. Verify .env is gitignored: `grep -q "\.env" .gitignore`
3. Check for PII: `git diff --staged | grep -iE "(\d{3}-\d{2}-\d{4})"`

## Commit Style
- Lowercase, imperative mood, under 50 chars
- No AI attribution (no Co-Authored-By: Claude)
- No em dashes in commit messages

## PR Splitting
1. Scaffolding and deps → 2. Data models → 3. Feature → 4. Tests → 5. Error handling → 6. Docs

## Blocked Content
Never commit: API keys, passwords, private keys, connection strings, PII, debug credentials.
