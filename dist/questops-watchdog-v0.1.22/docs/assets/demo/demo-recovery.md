# Recovery Alerts — Demo

This document shows how recovery alerts work when a previously-failing check passes again.

## How It Works

1. When a check fails, the alert ID is added to `active_failures` in the server's state file
2. A failure embed (red/orange) is sent to Discord
3. On the next run, if the check now passes and `active_failures` is non-empty, a recovery embed (green) is sent
4. After recovery, the `active_failures` list is cleared

## Before Recovery: State File with Active Failure

`state/minecraft-server/state.json`:
```json
{
  "active_failures": ["process_stopped"],
  "alerts": {
    "process_stopped": {
      "last_sent": "2026-05-19T11:55:00Z"
    }
  }
}
```

## Run 1 — Failure Detected

```
[SERVER] Minecraft
  PROCESS : STOPPED
  [ALERT] Discord alert sent (process_stopped)
```

**Discord alert**: Red embed titled "Process Stopped" for Minecraft.

## Run 2 — Recovery Detected

The server process has been restarted:

```
[SERVER] Minecraft
  PROCESS : Running
  [ALERT] Recovery sent: process_stopped -> recovered
```

**Discord alert**: Green embed titled "Process Recovered" for Minecraft.

## After Recovery: State File

`state/minecraft-server/state.json`:
```json
{
  "active_failures": [],
  "alerts": {
    "process_stopped": {
      "last_sent": "2026-05-19T12:00:00Z"
    }
  }
}
```

The `active_failures` array is now empty. No recovery alert will be sent on subsequent runs unless a new failure occurs.

## Recovery Alert Rules

| Condition | Behavior |
|-----------|----------|
| Check fails, no previous failure | Failure embed sent, added to active_failures |
| Check fails, already failing | Cooldown applies, no duplicate alert |
| Check passes, was failing | One recovery embed sent, active_failures cleared |
| Check passes, was not failing | No alert, state unchanged |
| Check passes, maintenance mode | No recovery alert (suppressed) |
| No webhook URL configured | No recovery alert (cannot send) |

## Console Output Example

```
============================================================
QuestOps Watchdog v0.1.22
Run: 2026-05-19 12:05:00
Config: C:\QuestOpsWatchdog\config\servers.production.json
============================================================

[SERVER] Minecraft
  PROCESS : Running (recovered)
  [RECOVERY] Discord recovery sent (process_stopped -> Running)

============================================================
Summary: 1 server(s), 1 check(s), 0 alert(s), 0 suppressed, 1 recovery alert(s).
```

The summary includes `1 recovery alert(s)` to indicate a recovery occurred.
