# hermes-hook-audit

Redacted JSONL audit logger for Hermes shell hooks.

This component records hook activity without changing agent behavior. It always
returns `{}` to Hermes and writes one JSON object per hook event.

## What It Logs

- UTC timestamp
- hook event name
- tool name
- session ID
- current working directory
- payload size
- command/result preview after redaction
- command SHA-256 when a terminal command is present

It does not log raw secret values. Previews are capped by
`HERMES_HOOK_AUDIT_MAX_CHARS` and default to 300 characters.

## Usage

Install:

```bash
bash setup.sh
```

Add it to Hermes hook config for events you want to observe:

```yaml
hooks:
  pre_tool_call:
    - command: "~/.hermes/agent-hooks/audit-hook.sh"
      timeout: 5
  post_tool_call:
    - command: "~/.hermes/agent-hooks/audit-hook.sh"
      timeout: 5
```

Default log path:

```text
~/.hermes/logs/hook-audit.jsonl
```

Override:

```bash
HERMES_HOOK_AUDIT_LOG=/path/to/audit.jsonl bash audit-hook.sh
```

## Notes

Store audit logs carefully. Even redacted logs may reveal project names,
commands, or workflow metadata.
