#!/usr/bin/env bash
# Approve a Discord pairing code shown by the bot in DM.
# Usage: ./scripts/pair.sh QLJ4W4UQ
set -euo pipefail
VM_NAME="openclaw"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <pairing-code>"
  echo
  echo "  1. DM your bot 'hello' in Discord."
  echo "  2. The bot replies with a pairing code (e.g. QLJ4W4UQ)."
  echo "  3. Run: $0 <that-code>"
  exit 1
fi

limactl shell "$VM_NAME" -- openclaw pairing approve discord "$1"
