# Security Policy

Do not include private API keys, personal phone numbers, local machine paths,
agent session logs, OAuth credentials, or production configuration in public
issues or pull requests.

To report a vulnerability, use the published maintainer contact for the public
repository or GitHub private vulnerability reporting if it is enabled.

Before publishing a release:

```bash
bash components/hermes/hermes-publish-gate/publish-gate.sh .
bash components/hermes/hermes-workspace-scanner/scan-workspace.sh .
```
