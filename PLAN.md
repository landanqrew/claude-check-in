# Automated Project Check-in System — Setup Guide

## Overview

This system uses **Claude Code in headless mode** to perform daily automated check-ins on your projects. It reads the project state, optionally writes code for the next step, and posts a status update to Slack. You stay in the loop without needing to be at the keyboard.

**How it works:**
```
┌──────────┐     ┌─────────────────┐     ┌───────────┐
│  Cron /  │────▶│  Claude Code    │────▶│  Slack    │
│  Schedule│     │  (headless -p)  │     │  Message  │
└──────────┘     │                 │     └───────────┘
                 │  Reads repo     │
                 │  Runs tests     │     ┌───────────┐
                 │  Writes code    │────▶│  Git      │
                 │  Posts to Slack │     │  Branch   │
                 └─────────────────┘     └───────────┘
```

---

## Prerequisites

- **Claude Max plan** (you're on this already ✅)
- **Node.js 18+** on the machine that will run check-ins
- **Git** configured with access to your repos
- A **Slack workspace** (free plan works fine)

---

## Step 1: Install Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:
```bash
claude --version
```

## Step 2: Authenticate Claude Code

Log in with your Max account (one-time, interactive):

```bash
claude login
```

This opens a browser for OAuth. Once complete, your session persists on this machine.

> **Important:** If running on a remote server/VPS, you may need to use `claude login --method browser-port-forward` or set an API key instead.

## Step 3: Create Your Slack App & Bot Token

Since you're on the free Slack plan, you'll create a simple Slack app:

1. Go to **https://api.slack.com/apps** and click **"Create New App"**
2. Choose **"From scratch"**
3. Name it something like `Claude Checkins` and select your workspace
4. Go to **OAuth & Permissions** in the sidebar
5. Under **Bot Token Scopes**, add:
   - `channels:read`
   - `channels:history`
   - `chat:write`
   - `groups:read` (if you want private channels)
   - `groups:history` (if you want private channels)
6. Click **"Install to Workspace"** and authorize
7. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

## Step 4: Create the Slack Channel

In your Slack workspace:

1. Create a new channel called **`#project-checkins`**
2. Invite your bot: type `/invite @Claude Checkins` in the channel
3. Note the **channel ID** — click the channel name at the top, scroll to the bottom of the popup. You'll see something like `C0123456789`

## Step 5: Set Up the Slack MCP Server

Claude Code uses MCP servers to interact with external services. You have a few options for Slack:

### Option A: Korotovsky Slack MCP Server (Recommended — Most Full-Featured)

```bash
# Install globally
npm install -g @anthropic-ai/claude-code

# The MCP server itself
git clone https://github.com/korotovsky/slack-mcp-server.git
cd slack-mcp-server
go build -o slack-mcp-server mcp/mcp-server.go
```

Or use the Docker approach:
```bash
docker pull ghcr.io/korotovsky/slack-mcp-server:latest
```

### Option B: Simple Webhook Approach (Lightest Weight)

If you only need Claude to **post** messages (not read), you can use a Slack Incoming Webhook instead of a full MCP server. This is simpler but less powerful.

1. In your Slack app settings, go to **Incoming Webhooks** → Enable
2. Add a webhook for `#project-checkins`
3. Claude can then use `curl` to post messages via the webhook URL

### Configure MCP in Claude Code

Edit your Claude Code MCP settings. The config file location depends on your OS:

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux:** `~/.config/claude/claude_desktop_config.json`

Add the Slack MCP server:

```json
{
  "mcpServers": {
    "slack": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "SLACK_BOT_TOKEN=xoxb-your-bot-token-here",
        "ghcr.io/korotovsky/slack-mcp-server:latest"
      ]
    }
  }
}
```

Or if you built from source:
```json
{
  "mcpServers": {
    "slack": {
      "command": "/path/to/slack-mcp-server",
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-bot-token-here"
      }
    }
  }
}
```

## Step 6: Add CLAUDE.md to Your Project

Copy the `CLAUDE.md` file from this package into the root of your InkSight repository. This is the file Claude reads for project context and priorities.

**Update the "Current Priorities" section** whenever your focus changes — this is what drives Claude's daily decisions.

```bash
cp CLAUDE.md /path/to/inksight/CLAUDE.md
```

## Step 7: Set Up the Check-in Script

Copy the script and make it executable:

```bash
cp daily-checkin.sh /path/to/inksight/daily-checkin.sh
chmod +x /path/to/inksight/daily-checkin.sh
```

Test it manually first:
```bash
cd /path/to/inksight
./daily-checkin.sh
```

You should see Claude analyze the project and post to `#project-checkins`.

## Step 8: Schedule with Cron

Open your crontab:
```bash
crontab -e
```

Add a daily check-in at 9:00 AM (adjust timezone as needed):
```cron
# InkSight daily check-in at 9 AM Central
0 9 * * * /path/to/inksight/daily-checkin.sh /path/to/inksight >> /tmp/claude-checkin.log 2>&1
```

### Alternative: Multiple Check-ins Per Day
```cron
# Morning check-in at 9 AM
0 9 * * * /path/to/inksight/daily-checkin.sh /path/to/inksight

# Afternoon check-in at 2 PM
0 14 * * * /path/to/inksight/daily-checkin.sh /path/to/inksight
```

### Alternative: Weekdays Only
```cron
# Weekdays at 9 AM
0 9 * * 1-5 /path/to/inksight/daily-checkin.sh /path/to/inksight
```

---

## Adding More Projects

To add another project, just:

1. Create a `CLAUDE.md` in that project's repo with its specific context
2. Add another cron entry pointing to that project's directory
3. Update the check-in script's `SLACK_CHANNEL` or use separate channels per project

Example multi-project cron:
```cron
0 9 * * * /path/to/inksight/daily-checkin.sh /path/to/inksight
0 9 * * * /path/to/other-project/daily-checkin.sh /path/to/other-project
```

---

## Troubleshooting

### Claude Code says "not authenticated"
Run `claude login` again on the machine. Sessions can expire.

### Slack messages aren't posting
- Verify the bot token is correct
- Make sure the bot is invited to the channel (`/invite @Claude Checkins`)
- Check that the MCP server is configured and running

### Check-in takes too long or hits turn limit
- Increase `MAX_TURNS` in the script (default: 15)
- Simplify the prompt to focus on reporting only (skip code writing)
- Add `--max-turns 5` for a quick status-only check

### Logs
Check the log directory for session output:
```bash
ls ~/.claude-checkins/logs/
cat ~/.claude-checkins/logs/checkin_2026-02-23_09-00-00.log
```

---

## Cost & Usage Notes

- Running on your **Max plan**, each check-in consumes usage from your subscription
- A typical check-in session uses roughly the equivalent of a 10-15 minute interactive session
- One daily check-in per project should have negligible impact on your Max allowance
- If you scale to 5+ projects with multiple daily check-ins, consider switching to an API key for the automation to keep your interactive usage separate

---

## Security Notes

- The bot token gives Claude read/write access to channels it's invited to — only invite it to channels you want it to access
- The `--allowedTools` flag in the script restricts what Claude can do (no arbitrary bash commands)
- Claude is explicitly instructed to never push to main or merge PRs
- All sessions are logged for auditability
- Consider running on a dedicated machine or VM for isolation
