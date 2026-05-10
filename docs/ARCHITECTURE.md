# Architecture

## Components

| Layer | Where | Purpose |
|---|---|---|
| Discord client | Your phone/desktop | UI for you |
| Discord servers | Discord cloud | Routes your DMs to the bot |
| Bot connection | `gateway.discord.gg` (WebSocket) | Bot listens for DMs |
| OpenClaw gateway | Inside Lima VM | Bridges Discord ↔ Claude, enforces tools/approvals |
| Claude API | `api.anthropic.com` | The actual model |
| Workspace | Host folder + virtiofs mount | The only host path the VM can see |

## Data flow

```
You DM bot
  → Discord routes to bot WebSocket
    → OpenClaw receives the message
      → checks ownerAllowFrom (you?)
        → calls Claude with your message + workspace tools
          → Claude responds (maybe with a tool call)
            → if tool call needs approval, OpenClaw DMs you "approve?"
              → on approval, runs the tool inside the VM
                → result sent back as a Discord DM
```

## Why a VM

The Lima VM is the security boundary. Even if the AI agent goes rogue, an installed package is malicious, or a prompt injection attack succeeds, the blast radius stops at the VM. The VM can only:

- Talk to the public internet on port 443 (HTTPS)
- Read/write one folder on your Mac (`~/nik-ai-assistant-workspace`)

It cannot:

- Touch any other folder on your Mac
- Read your iCloud, browser data, SSH keys, or anything else
- Open a port that other devices on your network can reach (gateway binds to loopback only)

## Why Discord (not a web UI)

- DMs are encrypted in transit
- Discord handles auth — you log into Discord, bot trusts your user ID
- Mobile-friendly without building an app
- Approval prompts work as DMs naturally

## Threat model

Threats this design defends against:

- **Prompt injection** — agent reads a malicious doc and tries to exfiltrate data. *Defense:* workspace-only FS, no exec, approval prompts on writes.
- **Malicious npm package** — a dependency tries to read host files. *Defense:* runs inside VM, host has no path mounted besides workspace.
- **Compromised Anthropic key** — leaked key gets abused. *Defense:* monthly spend cap on the key in Anthropic Console.
- **Compromised Discord token** — leaked token lets attacker impersonate the bot. *Defense:* `ownerAllowFrom` allowlist means even with the token, attacker can't DM commands and get them executed.

Threats this design does **not** defend against:

- Compromised Mac itself (rootkit, infostealer with disk access). If your Mac is owned, all bets are off.
- Anthropic-side data leak (your API calls are visible to Anthropic by their privacy policy).
- Discord-side data leak (your DM contents are visible to Discord).

## Secrets and where they live

| Secret | Where it lives | Why it's there |
|---|---|---|
| Anthropic API key | `~/.openclaw.env` inside VM (chmod 600) | Read at gateway startup |
| Discord bot token | `~/.openclaw.env` inside VM (chmod 600) | Read at gateway startup |
| Gateway auth token | Auto-generated in `~/.openclaw/openclaw.json` | Local-only, gateway uses internally |

Nothing in this repo contains secrets. Templates use placeholders.
