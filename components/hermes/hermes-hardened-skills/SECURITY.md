# Security Policy

## Reporting a vulnerability

If you find a security issue in hermes-hardened-skills, please report it privately:

- Open a private security advisory or contact the published maintainer address for this repository.
- **GitHub:** Open a private security advisory via the repo's Security tab

Please include: a description of the issue, steps to reproduce, and the impact you observed. I'll acknowledge within 72 hours and aim to ship a fix or mitigation within 14 days for confirmed issues.

## In scope

- Code execution, privilege escalation, or sandbox-escape bugs in any script under this repo
- Secret leakage via logs, error messages, or temp files
- Cryptographic weaknesses (key handling, IV reuse, MAC bypass, padding oracle)
- Dependency confusion or supply-chain risks

## Out of scope

- Issues only reproducible against forks with custom modifications
- Social engineering of project maintainers
- Findings that require pre-existing root or local-admin access (the threat model assumes the user already trusts their own machine)

## Disclosure

I prefer **coordinated disclosure**: report privately, give me a window to ship a fix, then we publish a joint advisory. If you'd like CVE assignment for a confirmed issue, I'll request one through GitHub.
