# Hardening

What's locked down in the shipped config, and why.

## Tool policy (`tools.profile: "minimal"`)

Starts from OpenClaw's most restrictive baseline. By default, the bot has only chat + read tools. Anything that writes, executes, browses, or talks to other systems is denied unless explicitly enabled.

## Filesystem (`tools.fs.workspaceOnly: true`)

The agent can only read/write inside its workspace folder (`/home/linux.user/workspace` inside the VM, mapped to `~/nik-ai-assistant-workspace` on your Mac). Any path outside is rejected.

## Shell execution (`tools.exec.security: "deny"`)

The `exec` tool — running shell commands — is denied entirely. Even if Claude tries to call it, OpenClaw refuses. Combined with `tools.exec.ask: "always"` and `tools.exec.strictInlineEval: true` so even if you ever flip security to `allowlist`, it still asks per-call and denies sneaky inline-eval forms like `python -c '...'`.

## Approval prompts (`approvals.exec.enabled: true`, `mode: "session"`)

When the agent wants to do something gated, it sends an approval prompt to the same Discord DM you're chatting in. You reply yes/no. No reply, no action. This applies to:

- Exec attempts (which are denied anyway, but you'd see the attempt)
- Plugin actions that gate themselves

## Owner allowlist (`commands.ownerAllowFrom`)

After pairing, only your Discord user ID can issue commands. Anyone else who DMs the bot is ignored. Even the bot's owner via the dev portal can't bypass this — it's enforced at the OpenClaw layer.

## Network bind (`gateway.bind: "loopback"`)

The OpenClaw gateway's HTTP server binds to `127.0.0.1` only. Other devices on your network cannot connect to it.

## API key spend cap

Set a monthly spend limit on your Anthropic key at [console.anthropic.com/settings/limits](https://console.anthropic.com/settings/limits). When hit, the key stops working until the next month. This is the only protection against runaway cost from a buggy or compromised agent.

## What's *not* hardened by this config

- **Outbound network**: the VM can reach any HTTPS host. The earlier per-IP allowlist approach was theater — services like Discord and Anthropic use rotating CDN IPs and you can't enumerate them. The real defense is the OpenClaw layer (FS, exec, approvals), which is intact regardless of network.
- **VM kernel**: standard Ubuntu 24.04. Patch with `sudo apt-get update && sudo apt-get upgrade` periodically.
- **Discord intents**: Message Content Intent is enabled (required for DM commands). The bot reads what you DM it.

## Adding capabilities later

Every capability you add (browser, exec, web search, extra channels) widens the blast radius. Read the OpenClaw docs for that capability and add the matching deny/approval rules at the same time. The pattern is: enable the tool, then immediately make it require approval.
