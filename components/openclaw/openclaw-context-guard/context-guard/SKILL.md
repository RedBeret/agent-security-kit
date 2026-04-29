---
name: context-guard
description: Proactive context management for long OpenClaw sessions. Prevents context degradation, manages compaction, and keeps sessions sharp. Use when sessions are getting long, the agent starts repeating itself, or the user asks about context health, compaction, session management, or token usage.
---

# Context Guard Skill

AI agents degrade as context grows. More history = more noise = worse decisions. You proactively manage this. Don't wait until the context is broken.

## Why Context Degrades

Every message carries the entire session history. After 20-30 exchanges:
- The model pays equal attention to old questions and current tasks
- Important instructions get diluted by conversational noise
- Token usage grows, costs rise, latency increases
- Earlier instructions drift out of the effective attention window

**Threshold:** Quality degrades around 70-80% of the model's context window.

## Session Load Order (Critical)

On every session start, load only what's needed:

1. System prompt / identity files
2. USER.md — user profile and preferences
3. Today's memory file only (`memory/YYYY-MM-DD.md`)

Do NOT auto-load:
- Full MEMORY.md (load on-demand when user asks about standing preferences)
- Past daily memory files (load on-demand when user asks about past work)
- Session history files

This reduces startup token cost by ~80%.

## Context Health Rules

### At the START of a new major task:
- Check current context size
- If over 50% of the model's window: offer to compact or start fresh

### During a long session:
- After completing a major subtask: write a brief checkpoint to memory
- After 30+ exchanges on a single topic: check if context is getting heavy
- If you start repeating yourself or missing earlier context: surface it immediately
  - "I think our context is getting long — want to compact and continue, or start fresh?"

### At the END of any substantive session:
Write to daily memory:
1. What was accomplished
2. Key decisions made
3. What's in progress
4. Next steps

## Compaction Decision Matrix

| Context % | Action |
|-----------|--------|
| < 50% | Normal operation, no action needed |
| 50-70% | Write checkpoint, continue working |
| 70-80% | Warn user, offer to compact or start fresh |
| > 80% | Compact immediately or start new session |

## Memory Checkpoint Format

```
## [Task Name] — [Status]
- Accomplished: [what was done]
- Decisions: [key choices made]
- In progress: [current work]
- Next: [immediate next steps]
```

## Signs of Context Degradation

Watch for these — they mean context management is needed:
- Repeating information already provided
- Asking questions already answered
- Responses becoming generic instead of project-specific
- Contradicting earlier decisions
- Longer response times
- Increased token usage per turn

## On-Demand Memory Loading

When the user asks about past work or preferences:

```
User: "What did we decide about the database?"
Agent: [searches memory/ files for relevant entries]
      → "We decided on PostgreSQL on 2026-03-15 (from daily memory)"
```

Don't load the entire memory store — search for the specific topic.
