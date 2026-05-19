# Summary Embed — Demo

This document shows a realistic grouped summary embed produced at the end of a watchdog run with four servers in different states.

## Configuration

```json
"summary": {
  "enabled": true,
  "sendOnlyOnIssues": false,
  "includeHealthyServers": true,
  "cooldownMinutes": 30
}
```

## Console Output

```
QuestOps Watchdog v0.1.22
Run: 2026-05-19 12:00:00
Config: C:\QuestOpsWatchdog\config\servers.production.json
ValidateConfig: Yes
============================================================
[ VALIDATE ] Config validation passed.

[SERVER] Valheim
  PROCESS : Running
  LOG     : Fresh
  BACKUP  : Fresh
  DISK    : OK (120 GB free)

[SERVER] Minecraft
  PROCESS : Running
  LOG     : Fresh
  BACKUP  : Fresh
  DISK    : OK (45 GB free)

[SERVER] 7 Days to Die
  PROCESS : STOPPED
  LOG     : Stale (last write 127 min ago)
  DISK    : OK (60 GB free)

[SERVER] Project Zomboid
  PROCESS : Running
  LOG     : Fresh
  DISK    : OK (15 GB free)

============================================================
Alerts sent: 2, Suppressed: 1, Recoveries: 1
```

## Summary Embed (Discord)

The summary embed sent to Discord would contain:

- **Title**: QuestOps Watchdog — Run Summary (2026-05-19 12:00)
- **Color**: Orange (issues present)
- **Fields**:

| Server | Status |
|--------|--------|
| Valheim | Healthy |
| Minecraft | Healthy |
| 7 Days to Die | Issue (1 failed: process_stopped) |
| Project Zomboid | Recovered (process was down, now running) |

### Rollup

- 4 servers, 13 checks
- 2 alerts sent (process stopped, log stale)
- 1 suppressed (cooldown active on disk alert)
- 1 recovery (process recovered)
- 2 healthy, 1 issue, 1 recovery

## Notes

- The summary embed only sends when `summary.enabled` is `true`
- `sendOnlyOnIssues: true` suppresses the summary when all servers are healthy
- `includeHealthyServers: false` hides healthy servers from the field list
- Summary has its own cooldown tracked in `state/__summary__/state.json`
