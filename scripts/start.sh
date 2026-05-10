#!/usr/bin/env bash
# Start the Nik AI Assistant gateway inside the VM.
set -euo pipefail
VM_NAME="openclaw"

limactl start "$VM_NAME" 2>/dev/null || true

limactl shell "$VM_NAME" -- bash -lc '
  source ~/.openclaw.env
  if pgrep -af "openclaw gateway" >/dev/null; then
    echo "Gateway already running."
    exit 0
  fi
  nohup openclaw gateway run --port 18789 > /tmp/gateway.log 2>&1 &
  disown
  sleep 5
  echo "Gateway started. Recent log:"
  tail -20 /tmp/gateway.log
'
