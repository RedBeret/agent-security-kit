# openclaw-context-guard

Skill that prevents context degradation in long AI agent sessions. Teaches proactive compaction, smart session loading, and memory checkpointing.

```
┌──────────────────────────────────────────────────────────────────┐
│                 Context Health Matrix                            │
│                                                                  │
│  Context Usage    Action                    Quality Impact       │
│  ────────────     ─────────────────────     ──────────────       │
│    < 50%          Normal operation           ████████████  High  │
│   50-70%          Write checkpoint           ████████░░░░  Good  │
│   70-80%          Warn + offer compact       █████░░░░░░░  Fair  │
│    > 80%          Compact NOW                ██░░░░░░░░░░  Poor  │
│                                                                  │
│  Signs of Degradation:                                          │
│  • Repeating information already given                          │
│  • Asking questions already answered                            │
│  • Generic responses instead of project-specific                │
│  • Contradicting earlier decisions                              │
└──────────────────────────────────────────────────────────────────┘
```

## The Problem

Every message carries the full session history. After 20-30 exchanges, context fills up and quality drops — the model pays equal attention to old noise and current tasks, earlier instructions drift out of the attention window, and token costs rise.

## What the Skill Teaches

### Session Load Order

Load only what's needed at startup:

1. System prompt / identity files
2. USER.md (user profile)
3. Today's memory file only (`memory/YYYY-MM-DD.md`)

**Don't** auto-load full MEMORY.md, past daily files, or session history. Load on-demand when the user asks. This reduces startup token cost by ~80%.

### Memory Checkpointing

After completing a major subtask:

```markdown
## [Task Name] — Completed
- Accomplished: what was done
- Decisions: key choices made
- In progress: current work
- Next: immediate next steps
```

This ensures context survives compaction.

### Compaction Configuration

```jsonc
# ~/.openclaw/openclaw.json
compression:
  enabled: true
  threshold: 0.5
  target_ratio: 0.2
  protect_last_n: 20
```

## Install

```bash
git clone https://github.com/RedBeret/openclaw-context-guard.git \
  ~/.openclaw/projects/openclaw-context-guard
cd ~/.openclaw/projects/openclaw-context-guard
bash setup.sh
```

## Requirements

- OpenClaw v0.8.0+ (skills system)

## License

MIT
