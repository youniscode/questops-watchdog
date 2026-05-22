# Client Simulation Intake - Demo Client 01

## Purpose

This file simulates what a real Fiverr client order could look like.

Use this file to collect the client requirements before creating the final QuestOps Watchdog config.

---

## Order Type

Fiverr simulation for QuestOps Watchdog setup.

---

## Client Scenario

The client runs one self-hosted Windows Project Zomboid dedicated server.

They want a lightweight local monitoring setup that sends Discord alerts when the server needs attention.

---

## Client Goal

Monitor the game server without using cloud dashboards or complex external services.

The client wants to know when:

- The server process stops
- The log folder stops updating
- Backups are stale
- Disk space is low
- A previous issue has recovered
- Planned maintenance is active

---

## Target Setup

- Game: Project Zomboid
- Operating system: Windows
- Server type: Self-hosted dedicated server
- Monitoring interval: Every 5 minutes
- Alert channel: Discord webhook
- Monitoring tool: QuestOps Watchdog

---

## Information Needed From Client

Use this section as your checklist for future real clients.

- Server display name
- Game type
- Operating system
- Process name
- Log folder path
- Backup folder path
- Disk drive to monitor
- Minimum free disk space threshold
- Log freshness threshold
- Backup freshness threshold
- Discord webhook URL
- Preferred alert cooldown
- Maintenance mode preference
- Maintenance flag path
- Permission to install Windows Scheduled Task

---

## Simulated Client Answers

### Server display name

### Server display name

Client PZ Server

### Game type

Project Zomboid

### Operating system

Windows

### Process name

ProjectZomboid64

### Log folder path

C:\GameServers\ProjectZomboid\logs

### Backup folder path

C:\GameServers\ProjectZomboid\backups

### Disk drive to monitor

C:\

### Minimum free disk space

20 GB

### Log freshness max age

30 minutes

### Backup max age

48 hours

### Discord webhook environment variable

QUESTOPS_DISCORD_WEBHOOK

### Alert cooldown

30 minutes

### Maintenance mode

Enabled

### Maintenance flag path

.\state\maintenance\client-pz-server.flag

### Scheduled task

Yes, every 5 minutes

Client PZ Server