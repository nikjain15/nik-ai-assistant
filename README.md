# Nik AI Assistant

A personal AI assistant you talk to through Discord DMs. Powered by [OpenClaw](https://openclaw.ai) + Anthropic's Claude, sandboxed inside a [Lima](https://lima-vm.io) VM on macOS.

## What it is

You DM a Discord bot. The bot is your AI assistant. It runs entirely on your laptop inside an isolated Linux VM, with strict permissions on what it can read, write, and execute. No cloud. No data leaves the VM except API calls to Anthropic and Discord.

## Capabilities

Baseline (always on):

- Chat with you using Claude Sonnet 4.5
- Read and write files in one workspace folder (and only that folder)
- Ask for your approval (via DM prompt) before any write or edit
- Persistent memory across sessions
- Only the paired owner can issue commands

Optional, you turn on per [docs/CAPABILITIES.md](docs/CAPABILITIES.md):

- Web search (Tavily, Brave, or Exa)
- Web fetch (read a single URL)
- Web browser (Chromium-driven page navigation, headless)
- Cron / scheduled tasks
- Multiple agents (separate personas with separate workspaces, e.g. writer / researcher / planner)

## What it cannot do

- Run shell commands (`exec` is denied by default)
- Touch files outside its workspace
- Talk to anyone but the paired owner

## Architecture

```
┌────────────────────────────┐
│   Your Mac                 │
│                            │
│   ┌────────────────────┐   │   API calls
│   │   Lima VM          │ ──┼──────────► api.anthropic.com
│   │   (Ubuntu 24.04)   │   │
│   │                    │ ◄─┼──────────► gateway.discord.gg
│   │   ┌────────────┐   │   │
│   │   │ OpenClaw   │   │   │
│   │   │ gateway    │   │   │
│   │   └────────────┘   │   │
│   └────────┬───────────┘   │
│            │ virtiofs       │
│   ┌────────▼───────────┐   │
│   │ ~/nik-ai-assistant-   │   │  ← only path the VM can see on host
│   │   workspace/       │   │
│   └────────────────────┘   │
└────────────────────────────┘
                ▲
                │ DM
                │
        ┌───────┴────────┐
        │  Discord (you) │
        └────────────────┘
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Prerequisites

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh)
- A Discord account
- An Anthropic account with a funded API key

Install dependencies:

```bash
brew install lima
```

## Quickstart

### 1. Get your secrets

- **Anthropic API key**: [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) → Create Key. **Set a monthly spend limit** at [console.anthropic.com/settings/limits](https://console.anthropic.com/settings/limits) before using it.
- **Discord bot**: follow [docs/DISCORD-SETUP.md](docs/DISCORD-SETUP.md) to create an app, get the bot token, and add the bot to a private server.

### 2. Clone and run setup

```bash
git clone https://github.com/<you>/nik-ai-assistant.git
cd nik-ai-assistant
./scripts/setup.sh
```

This installs Lima, creates the VM, installs OpenClaw, and stages template files.

### 3. Add your secrets and Discord app ID

```bash
limactl shell openclaw
nano ~/.openclaw.env                   # paste real ANTHROPIC_API_KEY and DISCORD_BOT_TOKEN
nano /tmp/openclaw.json.template       # replace REPLACE_WITH_YOUR_DISCORD_APP_ID
mkdir -p ~/.openclaw
cp /tmp/openclaw.json.template ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/openclaw.json
exit
```

### 4. Start the bot

```bash
./scripts/start.sh
```

Bot should come online in your Discord server (green dot).

### 5. Pair the bot

DM the bot `hello`. It replies with a pairing code (e.g. `QLJ4W4UQ`). Approve it:

```bash
./scripts/pair.sh QLJ4W4UQ
```

DM `hello` again — now you'll get a real reply from Claude.

## Daily use

```bash
./scripts/start.sh    # bring the bot online
./scripts/status.sh   # check it's healthy
./scripts/stop.sh     # take it offline
```

## Files in your workspace

Anything the bot writes lands in `~/nik-ai-assistant-workspace/` on your Mac. You can drop files there for the bot to read.

## Documentation

- [Capabilities](docs/CAPABILITIES.md) — full list and how to enable each
- [Architecture](docs/ARCHITECTURE.md) — what runs where, threat model
- [Hardening](docs/HARDENING.md) — what's locked down and why
- [Discord setup](docs/DISCORD-SETUP.md) — Discord app + bot creation
- [Anthropic setup](docs/ANTHROPIC-SETUP.md) — API key + spend cap

## License

MIT — see [LICENSE](LICENSE).
