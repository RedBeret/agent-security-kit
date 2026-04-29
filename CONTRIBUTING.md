# Contributing

Contributions are welcome when they keep the kit small, readable, and easy to
audit.

## Before Opening a PR

Run:

```bash
bash scripts/publish-check.sh
```

Also review `.security-allowlist`. New allowlist entries should be narrow,
file-specific, and justified by tests or documentation examples.

## Component Guidelines

- Prefer small Bash scripts over broad dependencies.
- Keep setup scripts explicit and easy to review.
- Never require users to store secrets in plaintext files.
- Avoid host-specific paths in committed code.
- Include a focused README for each component.
- Add smoke coverage when a hook or scanner behavior changes.

## Commit Messages

Use concise, human-readable commit messages. Do not include AI attribution
footers or generated-by text in commits.
