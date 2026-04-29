# openclaw-memory-encrypt

AES-256 encryption at rest for AI agent memory files. Your agent's `MEMORY.md` and `USER.md` contain behavioral notes, project context, and personal preferences — all sitting in plaintext on disk. This encrypts them when you're not running sessions and decrypts them on start.

Works with **OpenClaw**, **Hermes Agent**, and any agent that stores memory as Markdown files.

```
┌──────────────────────────────────────────────────────────────────┐
│                     Encryption Lifecycle                         │
│                                                                  │
│  Session Start              Active Session           Session End │
│  ┌─────────┐               ┌─────────────┐         ┌──────────┐ │
│  │ .enc    │──decrypt──▶   │  plaintext  │──────▶   │ encrypt  │ │
│  │ (disk)  │   + HMAC      │  (in use)   │          │ + wipe   │ │
│  └─────────┘   verify      └─────────────┘          └──────────┘ │
│       ▲                                                  │       │
│       └──────────── key from OS keystore ────────────────┘       │
└──────────────────────────────────────────────────────────────────┘
```

## What It Does

- **AES-256-CBC** with raw 256-bit key from your OS keystore (no PBKDF2 round needed — keystore already protects the key)
- **Random IV** per encryption — same plaintext never produces same ciphertext
- **HMAC-SHA256** integrity tag — detects tampering before decryption
- **Secure wipe** — plaintext overwritten with random data then deleted
- **Automatic backups** — keeps last 5 encrypted versions before overwriting
- **Legacy format support** — auto-detects and upgrades old 2-line format
- **Key in OS keystore** — macOS Keychain, Linux secret-tool, or pass (GPG)

## Install

```bash
git clone https://github.com/RedBeret/openclaw-memory-encrypt.git \
  ~/.openclaw/projects/openclaw-memory-encrypt
cd ~/.openclaw/projects/openclaw-memory-encrypt
bash setup.sh
```

Setup generates a 256-bit key and stores it in your OS keystore. Nothing touches disk.

## Usage

### Manual

```bash
bash ~/.openclaw/encrypt-memories.sh   # after session ends
bash ~/.openclaw/decrypt-memories.sh   # before session starts
```

### Automatic (Recommended)

Add to your launcher script:

```bash
# Start
bash ~/.openclaw/decrypt-memories.sh
openclaw gateway

# After exit
bash ~/.openclaw/encrypt-memories.sh
```

Or use OpenClaw shell hooks in `~/.openclaw/openclaw.json`:

```json
{
  "hooks": {
    "on_session_start": [
      { "command": "~/.openclaw/decrypt-memories.sh", "timeout": 5 }
    ],
    "on_session_end": [
      { "command": "~/.openclaw/encrypt-memories.sh", "timeout": 5 }
    ]
  }
}
```

## Encrypted File Format

```
Line 1: IV (hex, 32 chars) — unique per encryption
Line 2: HMAC-SHA256 (hex) — integrity verification
Line 3+: ciphertext (base64-encoded AES-256-CBC output)
```

On decrypt, the HMAC is verified first. If someone modified the `.enc` file, decryption is refused with a clear tamper warning.

## Key Management

### View your key

```bash
# macOS
security find-generic-password -a "$USER" -s "OPENCLAW_MEMORY_KEY" -w

# Linux (secret-tool)
secret-tool lookup service openclaw key OPENCLAW_MEMORY_KEY

# Linux (pass)
pass show openclaw/OPENCLAW_MEMORY_KEY
```

### Rotate your key

```bash
bash ~/.openclaw/decrypt-memories.sh       # decrypt with old key
# Delete old key, run setup.sh to generate new one
bash setup.sh
bash ~/.openclaw/encrypt-memories.sh       # re-encrypt with new key
```

### Backups

Encrypted backups are kept at `~/.openclaw/backups/memory/`. The last 5 versions of each file are retained automatically.

## Threat Model

| Threat | Protected? | Notes |
|--------|-----------|-------|
| Laptop stolen while powered off | Yes | Files encrypted, key in Secure Enclave (macOS) |
| Backup contains memory files | Yes | Only `.enc` files exist when agent isn't running |
| Attacker modifies `.enc` file | Yes | HMAC check fails, decryption refused |
| Process reads files during session | No | Plaintext exists while agent runs — use per-session RAM disk for stronger protection |
| Keystore compromised | No | If they have your keychain, they have everything |
| Forensic recovery of "wiped" plaintext | Partial | See caveat below |

### Caveats

**Secure wipe is best-effort, not forensic-grade.** This script overwrites the plaintext with random bytes (`shred` on Linux, `dd if=/dev/urandom` on macOS) and then `rm`s it. On modern filesystems (APFS, btrfs, ZFS) and SSDs with wear-leveling, the original blocks are typically not overwritten in place, so a forensic tool with disk-level access could potentially recover them. Full-disk encryption (FileVault on macOS, LUKS on Linux) is the actual mitigation if that's in your threat model.

**Why raw key, not PBKDF2.** The script reads a 64-hex-character key directly from the OS keystore and uses it as the AES key. This is intentional — the keystore already provides strong key protection (Keychain / libsecret / GPG), so an extra PBKDF2 round on top would only slow startup without adding security. If you'd rather use a passphrase, drop `-K`/`-iv` and pass a passphrase via `-pass`.

## Requirements

- `openssl` (pre-installed on macOS and most Linux)
- macOS Keychain **or** Linux `secret-tool` (libsecret) **or** `pass` (GPG)

## License

MIT
