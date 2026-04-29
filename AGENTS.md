# Agent Instructions

These rules apply to all agent-driven work in this repository.

## Git Workflow

- Do not push directly to `main`.
- Make every change on a small topic branch.
- Open a pull request for every change, including documentation-only changes.
- Keep PRs incremental and focused on one concern.
- Run `bash scripts/publish-check.sh` before opening or updating a PR.
- Do not merge automated dependency or security PRs without reviewing the diff.

The only exception was the initial repository publication. Future Codex work
should use pull requests.
