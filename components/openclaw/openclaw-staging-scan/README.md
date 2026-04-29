# openclaw-staging-scan

ClamAV-powered file scanner for AI agent inbound files. Drop files into a staging folder, scan them, and only clean files enter your workspace. Infected files are quarantined with timestamps.

```
┌──────────────────────────────────────────────────────────────────┐
│                    File Flow                                     │
│                                                                  │
│  External files                                                  │
│       │                                                          │
│       ▼                                                          │
│  ┌─────────────┐     clamscan      ┌──────────────┐             │
│  │  inbound/   │────────────────▶  │  scanned/    │  ✓ Clean   │
│  │  (drop zone)│                   │  (safe zone) │             │
│  └─────────────┘         │         └──────────────┘             │
│                          │                                       │
│                     FOUND ▼                                      │
│                    ┌──────────────┐                              │
│                    │ quarantine/  │  ✗ Infected                 │
│                    │ + timestamp  │  + macOS notification        │
│                    └──────────────┘                              │
└──────────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/RedBeret/openclaw-staging-scan.git \
  ~/.openclaw/projects/openclaw-staging-scan
cd ~/.openclaw/projects/openclaw-staging-scan
bash setup.sh
```

## Usage

```bash
# Drop files into the inbound folder, then scan
cp ~/Downloads/document.pdf ~/.openclaw/staging/inbound/
bash ~/.openclaw/staging-scan.sh

# Or scan a specific file/directory
bash ~/.openclaw/staging-scan.sh ~/Downloads/suspicious-file.zip
bash ~/.openclaw/staging-scan.sh ~/Downloads/
```

## Without ClamAV

If ClamAV isn't installed, files are moved to `scanned/` without scanning (with a warning). Install ClamAV for actual protection:

```bash
# macOS
brew install clamav && freshclam

# Linux
sudo apt install clamav && sudo freshclam
```

## Pairs Well With

- **[openclaw-smart-launcher](../openclaw-smart-launcher)** — drains staging inbound during Phase 7b
- **[openclaw-workspace-scanner](../openclaw-workspace-scanner)** — broader workspace security scan

## Requirements

- bash (standard)
- ClamAV (optional but recommended)

## License

MIT
