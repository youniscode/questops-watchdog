# Release Packaging — Demo

This document shows the release packaging workflow using `package_release.ps1`.

## Packaging Command

```powershell
# Default: reads version from VERSION file
powershell -File scripts\package_release.ps1
```

## Console Output

```
Packaging QuestOps Watchdog v0.1.22...

SUCCESS: Release v0.1.22 packaged.
  Version:     v0.1.22
  Release dir: C:\DevProjects\questops-watchdog\dist\questops-watchdog-v0.1.22
  ZIP:         C:\DevProjects\questops-watchdog\dist\questops-watchdog-v0.1.22.zip
  Files:       21
```

## Generated Structure

```
dist\questops-watchdog-v0.1.22\
├── config\
│   ├── servers.example.json
│   ├── servers.local.test.json
│   └── servers.production.template.json
├── scripts\
│   ├── questops_watchdog.ps1
│   ├── validate_config.ps1
│   ├── install_task.ps1
│   ├── uninstall_task.ps1
│   ├── package_release.ps1
│   └── test_discord.ps1
├── lib\
│   ├── checks.ps1
│   ├── discord.ps1
│   └── state.ps1
├── docs\
│   └── install.md
├── README.md
├── CHANGELOG.md
├── VERSION
├── PROJECTMAP.md
└── AI_WORKSPACE_RULES.md
```

Also creates: `dist\questops-watchdog-v0.1.22.zip`

## Custom Version

```powershell
# Explicit version (with or without "v" prefix)
powershell -File scripts\package_release.ps1 -Version "0.1.22"
```

## What Is Included

- All config JSON files
- All PowerShell scripts (runner, validator, installer, uninstaller, packager, test)
- All library modules (checks, discord, state)
- Documentation (install guide)
- Root files: README.md, CHANGELOG.md, VERSION, PROJECTMAP.md, AI_WORKSPACE_RULES.md

## What Is Excluded

- `.git\`, `.gitignore` — version control
- `logs\` — runtime logs (`*.log`)
- `state\` — runtime state files
- `dist\` — previous build artifacts
- `__*.json` — temporary test configs

## Characteristics

- Idempotent: running twice produces identical output
- Self-cleaning: removes previous release folder and ZIP before rebuilding
- Portable: output is a single ZIP file for deployment to any Windows machine
- PowerShell 5.1 compatible: no additional tools required
