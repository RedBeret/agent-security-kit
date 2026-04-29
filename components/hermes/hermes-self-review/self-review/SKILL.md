---
name: self-review
description: Code review and quality checks before delivering work. Use whenever the agent finishes writing code, creating a script, building a feature, or completing any task that produces code output. Triggers on code delivery, task completion, review, self-review, check-work, verify, quality, or when about to present finished code to the user.
---

# Self-Review Skill

Before delivering ANY code, run through this checklist. No exceptions.

## Code Review — Before Delivering

1. **Does it run?** Execute it. Don't assume. If you can't run it, explain what would need to happen.
2. **Does it handle errors?** Try bad input — empty strings, None, missing files, network failures.
3. **Secrets?** Scan for key patterns: `grep -rE "(sk-ant-|nvapi-|AKIA|password\s*=)" .`
4. **SQL injection?** Any f-string or string concatenation in SQL? Use parameterized queries.
5. **Imports real?** Verify every import exists. AI hallucinates ~20% of package names.
6. **Tests pass?** Run them. If none exist, test manually with at least 3 cases.
7. **Matches style?** Read 3 adjacent files first. Match naming conventions and patterns.

## Common Mistakes — Check Every Time

| Mistake | How to catch |
|---------|-------------|
| Hardcoded paths | `grep -r '/Users/\|/home/' .` |
| Debug code left in | `grep -r 'print(\|console.log\|pdb\|breakpoint\|debugger' .` |
| Wrong model IDs | Check against current model list, not training data |
| Stale references | grep for old project names, deprecated tools, removed functions |
| Overly broad except | `except Exception` hides bugs — catch specific errors |
| Hallucinated imports | `pip show PACKAGE` or `npm list PACKAGE` to verify |
| Placeholder text | `grep -rn 'TODO\|FIXME\|HACK\|XXX\|YOUR_' .` |
| Missing type hints | Python functions should have type annotations |
| Unclosed resources | Files, connections, sessions — use context managers |
| Race conditions | Shared state without locks, async without awaiting |

## Edge Case Checklist

For every function you write, consider:
- What if the input is empty? (`""`, `[]`, `{}`, `None`)
- What if the input is huge? (1M rows, 100MB file)
- What if the file/path doesn't exist?
- What if the network is down?
- What if permissions are denied?
- What if the user cancels mid-operation?

## Repo Review — Before Publishing

1. README makes sense to a stranger
2. Fresh clone + README steps actually work
3. No dead links, no placeholder text
4. License file exists
5. .gitignore covers .env, __pycache__, node_modules, .DS_Store
6. No hardcoded paths that only work on your machine

## Post-Delivery

After the user confirms the code works:
- Offer to write tests if none exist
- Offer to add error handling for edge cases you identified
- Note any technical debt in a TODO comment (specific, not vague)
