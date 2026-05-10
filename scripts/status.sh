#!/usr/bin/env bash
# Show VM, gateway, and Discord channel status.
set -euo pipefail
VM_NAME="openclaw"

echo "==> VM"
limactl list | head -3

echo
echo "==> Gateway process"
limactl shell "$VM_NAME" -- pgrep -af openclaw || echo "    not running"

echo
echo "==> Recent gateway log"
limactl shell "$VM_NAME" -- bash -lc 'tail -15 /tmp/gateway.log 2>/dev/null || echo "    no log yet"'

echo
echo "==> Channels"
limactl shell "$VM_NAME" -- openclaw channels list 2>&1 | head -10
