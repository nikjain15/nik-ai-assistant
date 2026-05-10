# Capabilities

What Nik AI Assistant can do, and how to enable each.

The shipped config (`config/openclaw.json.template`) ships **only the baseline**. Everything else is opt-in — turn it on by patching the live config inside the VM with `openclaw config patch` or `openclaw config set`. Add new capabilities one at a time so you can verify each works before stacking the next.

## Baseline (always on)

| Capability | Notes |
|---|---|
| Chat | Claude Sonnet 4.5 |
| Read workspace files | `~/nik-ai-assistant-workspace/` on host, `/home/<user>/workspace` in VM |
| Write workspace files | DM approval required |
| Edit workspace files | DM approval required |
| Persistent memory | `memory.backend: builtin` |
| Owner-only commands | After pairing, `commands.ownerAllowFrom` locks to your Discord ID |
| Loopback gateway | `gateway.bind: loopback` — no external clients |

## Optional capabilities

### Web search

A managed `web_search` tool. Picks results from a search provider.

Providers (pick one): [Tavily](https://tavily.com), [Brave Search](https://api.search.brave.com), [Exa](https://exa.ai). Free tiers exist for all three.

Add the provider's API key to `~/.openclaw.env` inside the VM (e.g. `export TAVILY_API_KEY="..."`), then patch:

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "tavily",                                // or "brave" or "exa"
        apiKey: { source: "env", provider: "default", id: "TAVILY_API_KEY" },
        maxResults: 5,
        timeoutSeconds: 15,
        cacheTtlMinutes: 30
      }
    }
  }
}
```

### Web fetch

Lets the bot pull a single URL's contents without launching a browser. Lighter than browser, no JS execution.

```json5
{ tools: { web: { fetch: { enabled: true } } } }
```

### Web browser

Headless Chromium for pages that require rendering or interaction. Heavier and higher risk than fetch — pages can carry prompt-injection content. Combine with `tools.exec.ask: "always"` so any side-effect actions still need approval.

Install Chromium inside the VM:

```bash
sudo apt-get install -y chromium-browser
```

Enable the browser tool:

```json5
{ tools: { alsoAllow: ["browser"] } }
```

### Cron / scheduled tasks

Run jobs on a schedule (e.g. "every weekday at 8am, summarize unread Gmail and DM me").

```json5
{ cron: { enabled: true, maxConcurrentRuns: 2 } }
```

Manage jobs with `openclaw cron` subcommands.

### Multiple agents (roles)

Define separate agents with their own workspaces, each appearing as a separate context. Useful for splitting `writer` / `researcher` / `planner` workloads so memory and files don't bleed across roles.

```bash
openclaw agents add writer \
  --workspace /home/<user>/workspace/writer \
  --model anthropic/claude-sonnet-4-5 \
  --non-interactive

openclaw agents add researcher \
  --workspace /home/<user>/workspace/researcher \
  --model anthropic/claude-sonnet-4-5 \
  --non-interactive
```

List with `openclaw agents list`. Customize each role's behavior with system prompts via `openclaw agents set-identity`.

## Capabilities NOT included in this template

These aren't enabled here, but OpenClaw supports them. Consult the [OpenClaw docs](https://docs.openclaw.ai) before adding — each one widens the blast radius.

- **Shell exec** (allowlisted commands) — denied by default in the shipped hardening
- **Slack / Telegram / WhatsApp channels** — additional chat surfaces
- **Gmail / Google Calendar / Notion / Linear / GitHub** — service integrations
- **Voice** (TTS/STT) — voice messages in/out
- **Image / video / music generation** — extra model providers

## Operating principle

Every new capability you enable should be paired with the matching restriction. The pattern in the shipped config is:

1. Enable the tool
2. Make it require approval (`approvals.exec.enabled: true, mode: "session"`)
3. Scope it (workspace-only, owner-only, allowlisted)
4. Cap the cost upstream (spend limit on the API key)
