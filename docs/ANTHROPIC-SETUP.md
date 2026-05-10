# Anthropic setup

How to get a Claude API key and protect yourself from runaway cost.

## 1. Create an account

[console.anthropic.com](https://console.anthropic.com) — sign in, add billing.

## 2. Set a monthly spend limit *first*

Before you generate a key, set a hard ceiling.

[console.anthropic.com/settings/limits](https://console.anthropic.com/settings/limits) → set **Monthly spend limit** to something you'd be OK losing if the bot misbehaves. $5–$20 is fine for personal use.

When the limit is hit, the key stops working until the next month. Anthropic enforces this server-side — there's no way for the bot to overrun it.

## 3. Create the key

[console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) → **Create Key**. Discord shows the key (`sk-ant-api03-...`) **once**. Copy it now.

Paste it into `~/.openclaw.env` inside the VM:

```
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

If the key is ever pasted into chat, screenshots, or git, **delete it from the console and create a new one**.

## 4. Optional: scope the key to a Workspace

Workspaces (in the console) let you have separate budgets per project. Useful if you run several Anthropic-backed tools. Create a Workspace, set its own limit, and create the key inside it.

## 5. Picking the model

The shipped config uses `claude-sonnet-4-5`. If cost matters more than quality, you can switch to Haiku — edit `agents.defaults.model` in `~/.openclaw/openclaw.json` and add the matching entry under `models.providers.anthropic.models`. Restart the gateway.
