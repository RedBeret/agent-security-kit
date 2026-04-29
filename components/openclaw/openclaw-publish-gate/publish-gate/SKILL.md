---
name: publish-gate
description: Pre-publish quality gate for GitHub repos. Use whenever the user wants to make a repo public, publish, release, ship, or open-source a project. Also triggers on mentions of publish, public, release, ship, open-source, go public, make public.
---

# Publish Gate Skill

All repos start PRIVATE. Before making any repo public, you MUST run the full publish-gate.

## When to Run

- User says "make it public", "publish", "ship it", "open source this"
- Before any `git push` to a public repo
- Before changing repo visibility from private to public
- Before creating a GitHub release

## The Gate

```bash
bash ~/.openclaw/publish-gate.sh /path/to/repo
```

If the script isn't installed, run these checks manually:

### Critical (must pass)
1. Secret scan entire git history: `git log -p | grep -iE "(sk-ant-|nvapi-|AKIA|ghp_|password\s*=)"`
2. Secret scan current files: `grep -rE "(sk-ant-|nvapi-|AKIA)" --include="*.py" --include="*.js" .`
3. PII patterns: `grep -rE "\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b" .`
4. Private keys: `git ls-files | grep -E "\.(pem|key|p12)$"`
5. .env not tracked: `git ls-files | grep "\.env"`

### High (should pass)
6. Git authors clean: `git log --format='%an %ae' | sort -u`
7. No AI attribution: `git log --format='%B' | grep -i "co-authored-by.*claude"`
8. README exists and is useful (not placeholder)
9. LICENSE file exists

### Advisory
10. No build artifacts tracked (`__pycache__/`, `node_modules/`)
11. Dependencies scanned (`pip-audit` / `npm audit`)
12. No debug code (`print(`, `console.log`, `breakpoint()`)

## If It Fails

Fix the issue, then re-run. Do NOT skip checks. Do NOT make the repo public until all critical/high checks pass.

## Common Fixes

| Issue | Fix |
|-------|-----|
| Secret in git history | `git filter-branch` or `git filter-repo` to remove, then force push |
| Wrong git author | `git rebase --root --exec 'git commit --amend --no-edit --author="Name <email>"'` |
| `__pycache__` tracked | `echo "__pycache__/" >> .gitignore && git rm -r --cached __pycache__/` |
| .env tracked | `echo ".env" >> .gitignore && git rm --cached .env` |
