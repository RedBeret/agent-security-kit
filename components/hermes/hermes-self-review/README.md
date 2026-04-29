# hermes-self-review

Skill + hook that teaches AI agents to review their own code before delivering. Catches the mistakes agents make most — hallucinated imports, debug code, hardcoded paths, overly broad exceptions, and missing error handling.

```
┌──────────────────────────────────────────────────────────────────┐
│                    The Review Pipeline                           │
│                                                                  │
│  Agent finishes code                                            │
│        │                                                         │
│        ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  1. Does it run?        Execute it, don't assume        │     │
│  │  2. Bad input?          Empty strings, None, huge files  │     │
│  │  3. Secrets leaked?     grep for key patterns            │     │
│  │  4. Imports real?       pip show / npm list to verify    │     │
│  │  5. Tests pass?         Run them or test manually x3     │     │
│  │  6. Style match?        Read 3 adjacent files first      │     │
│  └─────────────────────────────────────────────────────────┘     │
│        │                                                         │
│        ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  Common Mistakes Scan                                    │     │
│  │  ─────────────────                                       │     │
│  │  □ Hardcoded paths     grep '/Users/' .                  │     │
│  │  □ Debug code          grep 'print(\|console.log' .      │     │
│  │  □ Broad except        except Exception hides bugs       │     │
│  │  □ Placeholder text    TODO, FIXME, HACK, XXX            │     │
│  │  □ Missing types       Python functions need annotations  │     │
│  │  □ Unclosed resources  Use context managers               │     │
│  └─────────────────────────────────────────────────────────┘     │
│        │                                                         │
│        ▼                                                         │
│  Fix issues found → Deliver to user                             │
└──────────────────────────────────────────────────────────────────┘
```

## Why Agents Need Self-Review

AI agents produce code fast but also:
- Import packages that don't exist (~20% hallucination rate on package names)
- Leave debug `print()` and `console.log()` statements
- Hardcode paths like `/Users/yourname/...` that break on other machines
- Use `except Exception` that hides real bugs
- Skip error handling for edge cases
- Assume code works without running it

## Two Components

1. **`self-review/SKILL.md`** — Detailed review checklist loaded when the agent delivers code. Covers the full review pipeline, common mistakes table, and edge case checklist.

2. **`inject-review-reminder.sh`** — Optional `pre_llm_call` hook that injects a short reminder every turn: "Before delivering code, run it, test edge cases, scan for hardcoded paths."

## Install

```bash
git clone https://github.com/RedBeret/hermes-self-review.git \
  ~/.hermes/projects/hermes-self-review
cd ~/.hermes/projects/hermes-self-review
bash setup.sh
```

Optional hook in `~/.hermes/config.yaml`:

```yaml
hooks:
  pre_llm_call:
    - command: "~/.hermes/agent-hooks/inject-review-reminder.sh"
      timeout: 3
```

## Edge Case Checklist

For every function the agent writes, consider:

- What if the input is empty? (`""`, `[]`, `{}`, `None`)
- What if the input is huge? (1M rows, 100MB file)
- What if the file/path doesn't exist?
- What if the network is down?
- What if permissions are denied?
- What if the user cancels mid-operation?

## Requirements

- Hermes Agent v0.8.0+

## License

MIT
