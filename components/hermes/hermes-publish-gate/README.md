# hermes-publish-gate

12-check quality gate for repos before going public. Catches secrets in git history, PII, AI attribution, vulnerable dependencies, and missing docs — all in one script.

```
┌──────────────────────────────────────────────────────────────────┐
│                     The 12 Checks                                │
│                                                                  │
│  CRITICAL ─────────────────────────────────────────────────────  │
│  [1] Secret scan (git history)     [2] Secret scan (files)       │
│  [3] PII patterns                  [6] Private keys/certs        │
│  [8] .env tracked in git                                         │
│                                                                  │
│  HIGH ─────────────────────────────────────────────────────────  │
│  [4] Git author PII               [5] AI attribution             │
│  [9] README exists                [10] LICENSE exists             │
│                                                                  │
│  ADVISORY ─────────────────────────────────────────────────────  │
│  [7] Build artifacts tracked      [11] Dependency CVEs           │
│  [12] Debug code                                                 │
│                                                                  │
│  Result:  ALL critical pass → ✓ READY                            │
│           ANY critical fail → ✗ FIX FIRST                        │
└──────────────────────────────────────────────────────────────────┘
```

## Why This Exists

Making a repo public is **permanent**. Once secrets, PII, or debug credentials hit GitHub, they're in the public record forever — crawlers and forks preserve them even after deletion. You need an automated gate that runs every time, not a checklist you'll forget.

## Install

```bash
git clone https://github.com/RedBeret/hermes-publish-gate.git \
  ~/.hermes/projects/hermes-publish-gate
cd ~/.hermes/projects/hermes-publish-gate
bash setup.sh
```

## Usage

```bash
bash ~/.hermes/publish-gate.sh /path/to/your/repo
bash ~/.hermes/publish-gate.sh .    # current directory
```

## Example Output

```
╔══════════════════════════════════════╗
║     Publish Gate — myproject         ║
╚══════════════════════════════════════╝

  1. Secret scan (history)     ✓ PASS
  2. Secret scan (files)       ✓ PASS
  3. PII patterns              ✓ PASS
  4. Git author PII            ⚠ WARN — review authors
  5. AI attribution            ✓ PASS
  6. Private keys              ✓ PASS
  7. Build artifacts           ⚠ WARN — __pycache__/ tracked
  8. .env tracked              ✓ PASS
  9. README exists             ✓ PASS
 10. LICENSE exists             ✓ PASS
 11. Dependency CVEs           ⚠ WARN — 2 findings
 12. Debug code                ✓ PASS

Result: PASS with warnings (3 warnings, 9 passed)
```

## What Each Check Does

| # | Check | Catches |
|---|-------|---------|
| 1 | Secret history scan | `git log -p` for API keys across ALL commits |
| 2 | Secret file scan | Current files with key patterns (`sk-ant-*`, `AKIA*`, `ghp_*`, etc.) |
| 3 | PII patterns | SSN format (###-##-####) in source files |
| 4 | Git author PII | Real names / personal emails in commit history |
| 5 | AI attribution | `Co-Authored-By: Claude`, `AI-generated` in commits or source |
| 6 | Private keys | `.pem`, `.key`, `.p12` files tracked, or key content in source |
| 7 | Build artifacts | `__pycache__/`, `node_modules/`, `.pyc` in git |
| 8 | .env tracked | `.env` file committed (even if empty) |
| 9 | README | Exists and is more than a stub |
| 10 | LICENSE | Missing license = all rights reserved |
| 11 | Dependencies | `pip-audit` / `npm audit` if available |
| 12 | Debug code | `console.log`, `print(`, `breakpoint()`, `pdb` |

## Fixing Common Failures

| Issue | Fix |
|-------|-----|
| Secret in git history | `git filter-repo --invert-match --path-match 'secret'` then force push |
| Wrong git author | Rewrite history: `git rebase --root --exec 'git commit --amend --no-edit --author="Name <email>"'` |
| `__pycache__` tracked | `echo "__pycache__/" >> .gitignore && git rm -r --cached __pycache__/` |
| `.env` tracked | `echo ".env" >> .gitignore && git rm --cached .env` |

## Hermes Skill

The included `publish-gate/SKILL.md` teaches the agent to run the gate automatically before any push to a public repo or when you say "publish", "ship", or "make public."

## Requirements

- `git`, `grep`
- Optional: `pip-audit` (Python), `npm audit` (Node)

## License

MIT
