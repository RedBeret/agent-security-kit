# Contributing

Thanks for your interest in hermes-context-guard. PRs welcome — small, focused changes are easiest to review and merge quickly.

## Before you submit

1. **Run the publish-gate** (if installed): `bash ~/.hermes/publish-gate.sh .` — catches secrets, debug code, and missing docs.
2. **Lint your shell**: `shellcheck *.sh` (also runs in CI on every push).
3. **Test the change end-to-end** — these scripts run on real machines, so prefer manual smoke-testing over mocks.

## PR style

- One logical change per PR. Split scaffolding, refactors, and feature work.
- Title: lowercase imperative — `add openssl key validation`, `fix sed pattern in setup.sh`.
- Reference any related issue with `Closes #N`.
- **No AI attribution in commits** — no `Co-Authored-By: Claude` or similar.

## Reporting bugs

Open an issue with: OS + version, the command you ran, the output you got, and what you expected.

## Code of conduct

Be kind. Assume good faith. If something is wrong, say so directly and include a fix when you can.
