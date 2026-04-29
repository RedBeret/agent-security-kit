#!/usr/bin/env bash
# Runs the public-release checks against this repository.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/smoke-test.sh
bash components/hermes/hermes-publish-gate/publish-gate.sh .
bash components/hermes/hermes-workspace-scanner/scan-workspace.sh .
