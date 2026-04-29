# Egress Guard

## Never Leak
- API keys (sk-ant-*, nvapi-*, AKIA*, ghp_*, sk_live_*)
- Private keys (-----BEGIN * PRIVATE KEY-----)
- Connection strings with credentials (postgres://user:pass@host)
- Passwords in code (password = "...", secret = "...")
- PII (SSN patterns, credit card numbers)

## Safe Alternatives
- Use OS keystore (macOS Keychain / Linux secret-tool / pass)
- Use environment variables loaded from keystore
- Use .env for non-secret config only (timeouts, feature flags)
- Never dump env (env, printenv, export -p)
