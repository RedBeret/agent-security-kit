# Publish Gate

Before making ANY repo public, verify ALL of these:

## Critical (must pass)
1. Secret scan entire git history: `git log -p | grep -iE "(sk-ant-|nvapi-|AKIA|ghp_|password\s*=)"`
2. Secret scan current files
3. PII patterns (SSN, phone numbers)
4. No private keys (.pem, .key, .p12) tracked
5. .env not in git

## High (should pass)
6. Git authors clean (no personal emails)
7. No AI attribution in commits
8. README exists and is useful
9. LICENSE file exists

## Advisory
10. No build artifacts (__pycache__/, node_modules/)
11. Dependencies scanned (pip-audit / npm audit)
12. No debug code (print, console.log, breakpoint)
