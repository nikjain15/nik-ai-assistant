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

**Do not** use `apt-get install chromium-browser` on Ubuntu 24.04 — it installs the snap version, which AppArmor confines from writing to OpenClaw's profile directory. Use Playwright's bundled Chromium instead.

First open outbound port 80 in the VM (apt repos use HTTP):

```bash
sudo ufw allow out 80/tcp
```

Install Chromium via Playwright:

```bash
sudo npx -y playwright install --with-deps chromium
```

This puts Chromium under `~/.cache/ms-playwright/chromium-<build>/chrome-linux/chrome`. Note the path — you'll pin it in config.

Then patch the config to enable the tool, point at the Playwright binary, and disable Chromium's namespace sandbox (which fails inside the VM):

```json5
{
  tools: { alsoAllow: ["browser"] },
  browser: {
    enabled: true,
    headless: true,
    noSandbox: true,
    executablePath: "/home/<user>/.cache/ms-playwright/chromium-1217/chrome-linux/chrome"
  }
}
```

Replace `<user>` with your VM username and `1217` with the actual build number from your install.

Restart the gateway. Test with: *"Open https://example.com and tell me what's on the page."*

### Cron / scheduled tasks

Run jobs on a schedule (e.g. "every weekday at 8am, summarize unread Gmail and DM me").

Enable in config:

```json5
{ cron: { enabled: true, maxConcurrentRuns: 2 } }
```

Restart the gateway, then create jobs by DMing the bot in plain English:

> *"Schedule a job called 'morning-brief' to DM me a 3-bullet summary of overnight tech news every weekday at 8am."*

Or via CLI:

```bash
openclaw cron list                                  # list active jobs
openclaw cron remove <job-id>                       # delete a job
openclaw cron run <job-id>                          # run on demand
openclaw cron logs <job-id>                         # see past runs
```

`maxConcurrentRuns` is a backstop — if more jobs fire than this at once, the rest queue.

### Multiple agents (roles)

Define separate agents with their own workspaces, identities, and tool policies. Useful for splitting `writer` / `researcher` / `planner` workloads so memory, files, and behavior don't bleed across roles.

There are three layers to a role: **identity** (personality + system prompt), **skills/tools** (what it can do), and **routing** (which DM goes to which agent).

#### 1. Create the agent

```bash
openclaw agents add writer \
  --workspace /home/<user>/workspace/writer \
  --model anthropic/claude-sonnet-4-5 \
  --non-interactive
```

The workspace folder appears on your Mac at `~/nik-ai-assistant-workspace/<name>/` via the virtiofs mount.

#### 2. Set identity (system prompt)

Each agent reads a markdown file as its system prompt:

```
~/.openclaw/agents/<name>/agent/identity.md
```

Example for a `researcher`:

```markdown
# Researcher

You find sources, compare claims, and synthesize. Always cite URLs.
Flag contradictions and uncertainty. Default output: numbered findings
with sources, then a 3-sentence synthesis.
```

For display-level identity (name, emoji, theme color):

```bash
openclaw agents set-identity researcher
```

#### 3. Per-agent tool overrides (optional)

Tighten or loosen tools per agent. Examples:

```bash
# Writer: no web access at all
openclaw config set agents.entries.writer.tools.web.search.enabled false
openclaw config set agents.entries.writer.tools.web.fetch.enabled false

# Researcher: longer browser timeout
openclaw config set agents.entries.researcher.browser.actionTimeoutMs 60000
```

#### 4. Routing — which DM goes where

Route by keyword pattern so you don't bind/unbind manually:

```bash
# DMs starting with "research:" go to researcher
openclaw agents bind researcher --channel discord --pattern "^research:"

# DMs starting with "plan:" go to planner
openclaw agents bind planner --channel discord --pattern "^plan:"

# Anything else falls through to main
```

List + remove bindings:

```bash
openclaw agents bindings
openclaw agents unbind researcher --channel discord
```

#### Manage agents

```bash
openclaw agents list                # list all agents
openclaw agents delete <name>       # remove an agent (prompts for workspace cleanup)
```

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
