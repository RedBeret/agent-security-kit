# Component Categories

This file summarizes the component families. Each component directory has its
own README and setup script.

## Blocking Hooks

- Egress guard: stops secrets/PII/private keys before tool output is written.
- Safe terminal: stops commands likely to destroy data or leak credentials.
- Commit guard: reminds the agent of commit rules and can block AI-attribution
  commit messages with a `commit-msg` hook.

## Scanners and Gates

- Publish gate: release-readiness checks before making a repo public.
- Workspace scanner: local security scan for agent workspaces.
- Staging scan: ClamAV-backed inbound-file scan and quarantine workflow.

## Secret and State Handling

- Secret store: loads credentials from Keychain, libsecret, or `pass`.
- Memory encrypt: encrypts memory markdown files at rest.
- Brain backup: creates sanitized backups of agent configuration and skills.

## Agent Guidance

- Context guard: safe context-handling rules.
- Self review: final review checklist.
- Hardened skills: role prompts for security, full-stack, project planning, and
  cloud architecture.

## Maintenance

- Smart launcher: optional maintenance and health-check launcher. Review this
  before use because it can update packages and start local services.

## Suggested Install Order

1. Secret store
2. Egress guard
3. Safe terminal
4. Commit guard
5. Workspace scanner
6. Publish gate

Add memory encryption, staging scans, brain backups, and smart launchers only
after the core protections are working.
