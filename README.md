# Claude Check-in Bot

An automated project check-in system that uses Claude Code in headless mode to monitor your repos, optionally implement the next priority task, and post status updates to Slack — all on a cron schedule.

```
┌──────────┐     ┌─────────────────┐     ┌───────────┐
│  Cron    │────▶│  Claude Code    │────▶│  Slack    │
│  Schedule│     │  (headless -p)  │     │  #checkins│
└──────────┘     │                 │     └───────────┘
                 │  Reads repo     │
                 │  Runs tests     │     ┌───────────┐
                 │  Writes code    │────▶│  Local    │
                 │  Posts status   │     │  Branch   │
                 └─────────────────┘     └───────────┘
```

## How It Works

1. Cron fires `daily-checkin.sh` pointed at a project directory
2. Claude reads the project's `CLAUDE.md` for context and priorities
3. It assesses the repo: recent commits, git status, test results
4. If the next priority is small and clear → implements it on a feature branch
5. Posts a status update to Slack with what happened and what's next

If no `CLAUDE.md` exists, Claude creates one by reviewing the repo structure.

See [decision-tree.md](decision-tree.md) for the full branching logic.

## Quick Start

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- Claude Max subscription, authenticated (`claude login`)
- Slack MCP server configured (see [PLAN.md](PLAN.md) for setup)

### 1. Clone and configure

```bash
git clone https://github.com/landanqrew/claude-check-in.git
cd claude-check-in
cp .env.example .env
# Edit .env with your Slack channel name
```

### 2. Add a CLAUDE.md to your project

Copy the template into your target project and fill it out:

```bash
cp project-claude-md.template /path/to/your-project/CLAUDE.md
```

The **Current Priorities** section drives the bot's decisions. Keep it ordered — #1 gets picked up first.

### 3. Create a cron schedule

Add a `.cron` file in `local_crons/`:

```cron
# Every 3 hours from 9am-6pm, plus 11pm
0 9,12,15,18 * * * /path/to/claude-check-in/daily-checkin.sh /path/to/your-project
0 23 * * * /path/to/claude-check-in/daily-checkin.sh /path/to/your-project
```

Install it:

```bash
./add-local-crons.sh
```

See [cron-setup.md](cron-setup.md) for macOS permissions and troubleshooting.

### 4. Test manually

```bash
./daily-checkin.sh /path/to/your-project
```

Check logs at `~/.claude-checkins/logs/`.

## Project Structure

```
daily-checkin.sh            Main runner script
checkin-prompt.md           System prompt — the bot's brain
add-local-crons.sh         Installs .cron files into your crontab
local_crons/                Drop .cron files here (one per project)
project-claude-md.template  Template CLAUDE.md for target projects
decision-tree.md            Mermaid diagram of the decision logic
cron-setup.md               Cron installation guide
.env.example                Configuration reference
PLAN.md                     Full setup guide (Slack app, MCP, etc.)
```

## Safety

The bot is explicitly instructed to:

- **Never push** to remote
- **Never merge** to main
- **Never delete** branches
- **Always** work on a feature branch (`checkin/YYYY-MM-DD-description`)
- **Default to reporting only** when uncertain

All sessions are logged to `~/.claude-checkins/logs/` for auditability.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SLACK_CHANNEL` | `project-checkins` | Slack channel for status posts |
| `MAX_TURNS` | `15` | Max Claude turns per session |
| `LOG_DIR` | `~/.claude-checkins/logs` | Log output directory |

Set these in `.env` or as environment variables.

**Important:**
⏺ On macOS, you need to grant Full Disk Access to cron:                                                                                                                                         
                                                            
  1. System Settings → Privacy & Security → Full Disk Access                                                                                                                                    
  2. Click the + button (you may need to unlock with your password)                                                                                                                             
  3. Press Cmd+Shift+G to open the "Go to folder" dialog                                                                                                                                        
  4. Type /usr/sbin/cron and hit Enter                                                                                                                                                          
  5. Select it and click Open