#!/usr/bin/env bash
# Stop the gateway. VM keeps running.
set -euo pipefail
VM_NAME="openclaw"

limactl shell "$VM_NAME" -- bash -lc '
  openclaw gateway stop 2>/dev/null || true
  pkill -f "openclaw gateway" 2>/dev/null || true
  sleep 2
  if pgrep -af openclaw >/dev/null; then
    echo "Some processes still running:"
    pgrep -af openclaw
  else
    echo "Gateway stopped."
  fi
'
