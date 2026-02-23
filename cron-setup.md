# Cron Setup

## 1. Open your crontab

```bash
crontab -e
```

This opens your user's cron schedule in a text editor (usually vim). If it's your first time, it may be empty.

## 2. Paste the schedule

Replace both `/path/to/` entries with your actual paths, then add:

```cron
# Claude check-in: every 3 hours from 9am-6pm, plus 11pm
0 9,12,15,18 * * * /path/to/claude-check-in/daily-checkin.sh /path/to/your-project
0 23 * * * /path/to/claude-check-in/daily-checkin.sh /path/to/your-project
```

Save and exit (in vim: `:wq`).

## 3. Verify it saved

```bash
crontab -l
```

You should see your entries listed.

## 4. Make sure your machine is awake

Cron jobs only run if the machine is on and awake at the scheduled time. If you're on a Mac laptop, check:

- **System Settings → Energy → Prevent automatic sleeping when the display is off** (for desktops/plugged-in laptops)
- Or use `caffeinate` for a specific window: `caffeinate -s -t 86400` (keeps awake for 24 hours)

For reliable unattended runs, consider a server or always-on machine.

## 5. Troubleshooting

**Jobs not running?**

- Cron uses a minimal environment. If `claude` isn't found, use the full path (run `which claude` to find it) and update `daily-checkin.sh` or add the path in cron:
  ```cron
  PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
  ```
- On macOS, cron needs Full Disk Access. Go to **System Settings → Privacy & Security → Full Disk Access** and add `/usr/sbin/cron`.

**Want logs from cron itself?**

Append output redirection to each line:
```cron
0 9,12,15,18 * * * /path/to/claude-check-in/daily-checkin.sh /path/to/your-project >> /tmp/claude-checkin-cron.log 2>&1
```

## Schedule reference

| Time | What runs |
|------|-----------|
| 9:00 AM | Check-in |
| 12:00 PM | Check-in |
| 3:00 PM | Check-in |
| 6:00 PM | Check-in |
| 11:00 PM | Check-in |
