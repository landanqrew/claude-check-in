# Automated Project Check-in

You are performing an automated daily check-in on a software project. Your goal is to assess the project's current state, optionally implement the next priority task, and post a status update to Slack.

---

## Step 1: Read Project Context

Look for a `CLAUDE.md` file in the project root. If it exists, read it to understand:
- Project name and description
- Current priorities (ordered list)
- Tech stack and architecture
- Test command
- Build command
- Constraints

If no `CLAUDE.md` exists, note this in your status update and proceed with what you can infer from the repo structure.

## Step 2: Assess Current State

Run the following to understand where things stand:

1. `git log --oneline -20` — recent commit history
2. `git status` — uncommitted work or dirty state
3. `git branch` — active branches
4. Review key files (README, package.json, go.mod, pyproject.toml, etc.) if you haven't already from CLAUDE.md

If a test command is defined in CLAUDE.md, run the test suite and note the results.

## Step 3: Decide Whether to Implement

Based on the priorities in CLAUDE.md, decide:

**Implement if ALL of these are true:**
- A clear next task exists in the priority list
- The task is small enough to complete in a single session (roughly: a single feature, bug fix, or refactor touching fewer than ~5 files)
- The test suite passes (or no tests exist yet)
- The main branch is clean (no uncommitted changes)

**Report only (no code changes) if ANY of these are true:**
- No CLAUDE.md or no priorities defined
- The next task is too large or ambiguous
- The working tree is dirty
- Tests are failing
- You're unsure about the right approach

### If implementing:

1. Create a feature branch: `checkin/YYYY-MM-DD-short-description`
2. Implement the change with clean, focused commits
3. Run tests after your changes to verify nothing broke
4. Do NOT push to remote — leave the branch local

## Step 4: Post Status to Slack

Find the `#project-checkins` channel (use `mcp__claude_ai_Slack__slack_search_channels` if needed) and post a status update using `mcp__claude_ai_Slack__slack_send_message`.

Format the message as:

```
📋 *Project Check-in: [Project Name]*
📅 [Today's Date]

*Status:* [Clean / Dirty / Tests Failing]

*Recent Activity:*
[2-3 sentence summary of recent commits and current state]

*Today's Action:*
[What you did — either "Implemented X on branch checkin/..." or "Report only — no changes made"]

*Next Up:*
[What the next priority is, based on CLAUDE.md]

*Blockers/Concerns:*
[Any issues noticed, or "None"]
```

---

## Safety Rules

You MUST follow these rules — no exceptions:

- **Never push to remote** — all branches stay local
- **Never merge to main** — leave that for the human
- **Never delete branches** — only create new ones
- **Never force-push or rewrite history**
- **Always work on a new feature branch** — never commit directly to main
- **Branch naming:** `checkin/YYYY-MM-DD-short-description`
- **If in doubt, report only** — it's always safe to skip implementation and just post a status update
