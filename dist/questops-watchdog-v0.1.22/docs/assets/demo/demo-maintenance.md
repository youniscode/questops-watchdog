# Maintenance Mode — Demo

This document shows how maintenance mode suppresses Discord alerts while checks continue running.

## How It Works

1. Configure a `maintenance` section in the server's config entry
2. Create a flag file on disk to activate maintenance mode
3. The watchdog detects the flag file and suppresses Discord alerts for that server
4. Remove the flag file to deactivate maintenance — no config change needed

## Configuration

```json
{
  "name": "Valheim",
  "enabled": true,
  "maintenance": {
    "enabled": true,
    "flagPath": ".\\state\\maintenance\\valheim.flag",
    "suppressAlerts": true
  },
  "process": { "name": "valheim_server" },
  "disk": { "path": "D:\\Valheim\\server", "minFreeGB": 10 }
}
```

## Activating Maintenance

```powershell
# Create the flag file to enable maintenance mode
New-Item -ItemType File -Path ".\\state\\maintenance\\valheim.flag" -Force
```

## Console Output (Maintenance Active)

```
QuestOps Watchdog v0.1.22
Config: config\servers.production.json
============================================================

[ VALIDATE ] Config validation passed.

[SERVER] Valheim
  PROCESS : Running
  DISK    : OK (120 GB free)
  [MAINTENANCE] : active (alerts suppressed)

[SERVER] Minecraft
  PROCESS : STOPPED
  DISK    : OK (45 GB free)
  [ALERT] Discord alert sent (process_stopped)

============================================================
Summary: 2 server(s), 4 check(s), 1 alert(s) sent, 1 suppressed, 0 recovery alert(s).
```

Key points:
- Valheim checks ran and results are reported — process running, disk OK
- No Discord alert was sent for Valheim despite checks executing
- `[MAINTENANCE] : active (alerts suppressed)` is shown per server
- The suppressed count (1) appears in the summary
- Minecraft (not in maintenance) sent an alert normally

## Deactivating Maintenance

```powershell
# Remove the flag file to disable maintenance mode
Remove-Item -LiteralPath ".\\state\\maintenance\\valheim.flag"
```

After removal, the next run sends alerts normally for any failing checks.

## Behavior Details

- Cooldown timers still advance during maintenance (prevents alert flood on exit)
- State files are still updated (cooldowns, active failures)
- Logs still record check results with `[MAINTENANCE]` prefix
- Multiple servers can be in maintenance simultaneously using separate flag files
- Maintenance is config-independent: no JSON edit needed to toggle
