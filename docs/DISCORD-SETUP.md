# Discord setup

How to create a Discord application, get a bot token, and add the bot to a private server.

## 1. Create the application

1. Go to [discord.com/developers/applications](https://discord.com/developers/applications)
2. Click **New Application**, name it (e.g. "Nik AI Assistant"), accept terms.
3. Note the **Application ID** under General Information — you'll paste it into `openclaw.json` later.

## 2. Configure the bot

In the left sidebar, click **Bot**:

| Setting | Value |
|---|---|
| Public Bot | OFF |
| Requires OAuth2 Code Grant | OFF |
| Presence Intent | OFF |
| Server Members Intent | OFF |
| Message Content Intent | **ON** |

Click **Save Changes**.

## 3. Copy the bot token

Still on the Bot page, click **Reset Token** (or **Copy** if you've never reset it). Discord shows the token once — copy it now.

Paste it into `~/.openclaw.env` inside the VM:

```
export DISCORD_BOT_TOKEN="paste-here"
```

If the token is ever pasted into chat, screenshots, or git, **reset it immediately**.

## 4. Create a private server for the bot

1. In Discord, click the **+** at the bottom of the left server list.
2. Choose **Create My Own** → **For me and my friends**.
3. Name it whatever (e.g. "Nik AI Assistant").

## 5. Invite the bot to the server

Open this URL, replacing `<APP_ID>` with your Application ID from step 1:

```
https://discord.com/api/oauth2/authorize?client_id=<APP_ID>&scope=bot&permissions=100352
```

Permissions integer `100352` = Send Messages + Attach Files + Read Message History.

Pick your private server, click **Authorize**, complete the captcha. The bot joins as a member.

If you get **"Integration requires code grant"**: go back to step 2 and turn off **Requires OAuth2 Code Grant**. Save. Retry the URL.

If you get **"Private application cannot have a default authorization link"**: go to **Installation** in the left sidebar, set **Install Link** to **None** or **Discord Provided Link**, save, then retry.

## 6. Pair with your bot

1. Start the gateway: `./scripts/start.sh`
2. In Discord, find the bot in your server's member list (👥 icon top-right).
3. Click the bot → **Message** → opens a DM thread.
4. Send `hello`. The bot replies with a pairing code.
5. Approve the code: `./scripts/pair.sh <code>`

After pairing, your Discord user ID is stored in `commands.ownerAllowFrom`. Only you can issue commands going forward.
