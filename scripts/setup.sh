#!/usr/bin/env bash
# Nik AI Assistant — first-time setup
# Spins up the Lima VM, installs Node + OpenClaw, applies the hardened config.
# Run once, from the repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_NAME="openclaw"
HOST_WORKSPACE="$HOME/nik-ai-assistant-workspace"

echo "==> Checking prerequisites"
for cmd in lima limactl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing: $cmd. Install with: brew install lima"
    exit 1
  fi
done

echo "==> Creating host workspace at $HOST_WORKSPACE"
mkdir -p "$HOST_WORKSPACE"

echo "==> Starting Lima VM ($VM_NAME)"
if limactl list -q | grep -qx "$VM_NAME"; then
  echo "    VM already exists — starting if stopped"
  limactl start "$VM_NAME" 2>/dev/null || true
else
  limactl start --name="$VM_NAME" --tty=false "$REPO_ROOT/vm/lima-openclaw.yaml"
fi

echo "==> Installing Node.js 24 in VM"
limactl shell "$VM_NAME" -- bash -lc '
  if ! command -v node >/dev/null || ! node --version | grep -q "^v24"; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
  node --version
'

echo "==> Installing OpenClaw"
limactl shell "$VM_NAME" -- bash -lc 'sudo npm install -g openclaw@latest && openclaw --version'

echo "==> Copying env template into VM (you must fill it in next)"
limactl shell "$VM_NAME" -- bash -lc '
  if [ ! -f ~/.openclaw.env ]; then
    cat > ~/.openclaw.env <<EOF
# Fill these in, then chmod 600 ~/.openclaw.env
export ANTHROPIC_API_KEY=""
export DISCORD_BOT_TOKEN=""
EOF
    chmod 600 ~/.openclaw.env
  fi
  if ! grep -q "openclaw.env" ~/.bashrc; then
    echo "[ -f ~/.openclaw.env ] && source ~/.openclaw.env" >> ~/.bashrc
  fi
'

echo "==> Copying hardened config template into VM"
limactl cp "$REPO_ROOT/config/openclaw.json.template" "$VM_NAME":/tmp/openclaw.json.template

echo
echo "==================================================================="
echo "Setup complete. Next steps:"
echo
echo "  1. Edit your secrets:"
echo "       limactl shell $VM_NAME"
echo "       nano ~/.openclaw.env       # paste your API key + bot token"
echo
echo "  2. Edit the config template to add your Discord application ID,"
echo "     then install it as the live config:"
echo "       nano /tmp/openclaw.json.template"
echo "       mkdir -p ~/.openclaw && cp /tmp/openclaw.json.template ~/.openclaw/openclaw.json"
echo "       chmod 600 ~/.openclaw/openclaw.json"
echo
echo "  3. Start the gateway:"
echo "       ./scripts/start.sh"
echo
echo "  4. Pair the bot (see docs/DISCORD-SETUP.md)"
echo "==================================================================="
