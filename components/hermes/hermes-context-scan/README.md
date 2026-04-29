# hermes-context-scan

Scanner for prompt-injection and context-poisoning phrases in Hermes memory and
context files.

It is designed for private review before publishing or backing up an agent
workspace. Findings show only path, line number, and reason; the scanner does
not print memory contents.

## What It Checks

- prompt override language such as "ignore previous instructions"
- concealment instructions such as "do not tell the user"
- secret-exfiltration requests
- system/developer role-tag injection
- suspicious executable instructions inside memory
- base64/decode/eval style staging phrases

## Usage

Scan the default Hermes home:

```bash
bash context-scan.sh
```

Scan a specific directory:

```bash
bash context-scan.sh ~/.hermes
```

Use an allowlist for intentional fixtures:

```bash
ALLOWLIST_FILE=.context-scan-allowlist bash context-scan.sh .
```

## Install

```bash
bash setup.sh
```

This installs `context-scan.sh` into `~/.hermes/security/`.
