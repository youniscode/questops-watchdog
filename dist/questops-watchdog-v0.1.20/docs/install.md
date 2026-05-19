# Installation Guide

QuestOps Watchdog requires no installation. It runs as a Windows PowerShell 5.1 script.

## Requirements

- Windows 7 / Windows Server 2012 or later
- Windows PowerShell 5.1 (included with Windows)
- No admin rights required for basic operation
- No additional software or PowerShell modules

## Manual Setup

1. **Download or clone** the repository to a local folder:
   ```
   C:\QuestOps-Watchdog
   ```

2. **Configure servers** — Edit `config/servers.json` with your game server details:
   - Server name
   - Process name (e.g., `ProjectZomboid64.exe`)
   - Log file path and expected update interval
   - Backup directory path and expected freshness
   - Discord webhook URL

3. **Test Discord connection** (future):
   ```
   powershell -File scripts\test_discord.ps1
   ```

4. **Run manually** (future):
   ```
   powershell -File scripts\questops_watchdog.ps1
   ```

5. **Set up scheduled task** (future) — Run every 5 minutes:
   ```
   powershell -File scripts\install_task.ps1
   ```

## Future Installer

A future version may include:
- Interactive setup wizard
- Automated scheduled task creation
- Config file generation via guided prompts
- Log rotation configuration

For now, setup is manual via JSON config editing.
