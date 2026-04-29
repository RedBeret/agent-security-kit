# openclaw-hardened-skills

Four drop-in, security-hardened skills for AI agents. Each has commit guards, secret scanning, PII prevention, and publish-gate conventions baked into its instructions.

```
┌──────────────────────────────────────────────────────────────────┐
│                   Security Layer per Skill                       │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │ cybersecurity-   │  │ aws-architect    │                     │
│  │ advisor          │  │                  │                     │
│  │ ────────────     │  │ ────────────     │                     │
│  │ + secret scan    │  │ + IaC cred check │                     │
│  │ + egress rules   │  │ + IAM audit      │                     │
│  │ + PII blocklist  │  │ + pre-deploy gate│                     │
│  │ + STRIDE model   │  │ + blocked CDK/TF │                     │
│  └──────────────────┘  └──────────────────┘                     │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │ fullstack-       │  │ project-planner  │                     │
│  │ developer        │  │                  │                     │
│  │ ────────────     │  │ ────────────     │                     │
│  │ + branch flow    │  │ + sprint sec     │                     │
│  │ + commit style   │  │   checkpoints    │                     │
│  │ + PR splitting   │  │ + release gates  │                     │
│  │ + publish-gate   │  │ + egress protect │                     │
│  └──────────────────┘  └──────────────────┘                     │
│                                                                  │
│  All skills share: no hardcoded secrets · no PII · no AI        │
│  attribution · private by default · git identity rules          │
└──────────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/RedBeret/openclaw-hardened-skills.git \
  ~/.openclaw/projects/openclaw-hardened-skills
cd ~/.openclaw/projects/openclaw-hardened-skills
bash setup.sh
```

Or point OpenClaw at the repo directly (auto-updates with `git pull`):

```jsonc
# ~/.openclaw/openclaw.json
"skills":
"external_dirs":
    - ~/.openclaw/projects/openclaw-hardened-skills/skills
```

## What Each Skill Adds

### cybersecurity-advisor
OWASP Top 10, secure code review, network defense, cloud security, compliance frameworks. **Plus:** pre-commit secret scanning commands, egress protection rules, PII pattern blocklist, local security audit scripts.

### aws-architect
VPC design, IAM, CDK/Terraform, cost optimization, serverless. **Plus:** IaC credential safety (never hardcode in templates), pre-deploy security gate, IAM policy audit checklist, blocked patterns for CloudFormation.

### fullstack-developer
Flask/React, database design, API patterns, project structure. **Plus:** git branch workflow, commit style conventions, 6-PR splitting pattern, publish-gate checklist.

### project-planner
Agile/Scrum, sprint planning, user stories, estimation. **Plus:** pre-dev security gate (threat model, dependency audit), mid-sprint gate (secret scan, code review), release gates (full publish-gate).

## Customizing

Each skill is a standalone `SKILL.md` file:

```bash
vim ~/.openclaw/skills/cybersecurity-advisor/SKILL.md
```

Add company-specific patterns, change commit conventions, adjust the blocked patterns table.

## Requirements

- OpenClaw v0.8.0+

## License

MIT
