# hermes-mcp-guard

Offline guard for reviewing Hermes MCP server configuration before an agent
session uses external tools.

It scans the `mcp_servers:` block in `~/.hermes/config.yaml` and reports:

- literal API keys or bearer tokens in MCP config
- insecure `http://` MCP endpoints
- remote MCP hosts that are not explicitly allowlisted
- local/private MCP endpoints that deserve review
- stdio commands that shell out through `curl`, `wget`, `bash -c`, or `sh -c`
- `npx`, `uvx`, and `pipx` MCP packages that are not version-pinned
- enabled MCP servers that expose all tools instead of `tools.include` or
  `tools.exclude`
- server-initiated sampling with no visible `allowed_models` limit

The script does not connect to any MCP server and does not print secret values.

## Usage

Scan the default Hermes config:

```bash
bash mcp-guard.sh
```

Scan a specific config:

```bash
bash mcp-guard.sh ~/.hermes/config.yaml
```

Treat warnings as failures:

```bash
bash mcp-guard.sh --strict ~/.hermes/config.yaml
```

Allow known remote MCP hosts:

```bash
MCP_GUARD_ALLOWED_HOSTS_CSV="github.com,mcp.example.com" bash mcp-guard.sh
```

## Install

```bash
bash setup.sh
```

This installs `mcp-guard.sh` into `~/.hermes/security/`.

## Notes

This guard is deliberately text-based so it can run without extra YAML
dependencies. Review warnings manually; some local MCP servers are legitimate
when they are intentionally scoped and trusted.
