# Context Guard

## Session Load Order
Only load what's needed: system prompt, user profile, today's context.
Don't auto-load full history or all memory files.

## Context Health
- Under 50%: normal operation
- 50-70%: write checkpoint, consider compacting
- 70-80%: warn user, offer to compact
- Over 80%: compact immediately or start fresh

## Memory Checkpoints
After major subtasks, write: what was accomplished, decisions made, what's in progress, next steps.

## Signs of Degradation
- Repeating information already given
- Asking questions already answered
- Generic responses instead of project-specific
- Contradicting earlier decisions
