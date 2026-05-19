# Config Validation — Demo

This document shows realistic output from `validate_config.ps1` in three scenarios: clean pass, warnings, and failure.

## Scenario 1: Validation Passes (Clean)

A valid production config with one enabled server, proper paths, and env-var-based webhook URL.

```
QuestOps Watchdog Config Validator
Config: config\servers.production.json

[PASS] File exists and is valid JSON
[PASS] Required root fields present (productName, configVersion, global, discord, servers)
[PASS] servers array is non-empty
[PASS] Discord webhookUrlEnvVar is an environment variable name (not a URL)
[PASS] Server 'Valheim': required fields present
[PASS] Server 'Valheim': process.name present
[PASS] Server 'Valheim': logFile.maxAgeMinutes is a positive number
[PASS] Server 'Valheim': disk.minFreeGB is a positive number

Results: 8 passed, 0 warnings, 0 failed.
Validation PASSED.
```

## Scenario 2: Validation Passes with Warnings

Config passes but has non-critical issues: placeholder paths, missing metadata.

```
QuestOps Watchdog Config Validator
Config: config\servers.production.template.json

[PASS] File exists and is valid JSON
[PASS] Required root fields present
[PASS] servers array is non-empty
[PASS] Discord webhookUrlEnvVar is an environment variable name
[WARN] Server 'Valheim': process.name present, maxAgeMinutes present
[WARN] Server 'Valheim': enabled server missing 'category' field
[WARN] Server 'Valheim': enabled server missing 'tags' field
[WARN] Server 'Valheim': disk path C:\REPLACE_ME\... still contains placeholder
[WARN] Server 'Valheim': logFile path C:\REPLACE_ME\... still contains placeholder
[WARN] Server 'Minecraft': enabled server missing 'category' field
[WARN] Server 'Minecraft': enabled server missing 'tags' field
[WARN] Server 'Minecraft': disk path C:\REPLACE_ME\... still contains placeholder

Results: 4 passed, 7 warnings, 0 failed.
Validation PASSED.
```

## Scenario 3: Validation Fails

Config has critical errors: webhook URL in JSON, missing process name, negative threshold.

```
QuestOps Watchdog Config Validator
Config: config\servers.broken.json

[PASS] File exists and is valid JSON
[PASS] Required root fields present
[PASS] servers array is non-empty
[FAIL] Discord global webhookUrlEnvVar contains URL: https://discord.com/api/webhooks/...
       Webhook URLs must be set via environment variable, not in JSON config.
       Remove the URL and set it as an environment variable instead.
[FAIL] Server 'Valheim': enabled but process.name is missing
       Each enabled server must have a process.name to check.
[FAIL] Server 'Minecraft': logFile.maxAgeMinutes is not a positive number (value: -5)
       maxAgeMinutes must be a positive number (greater than 0).

Results: 3 passed, 0 warnings, 3 failed.
Validation FAILED.
```

## Command Reference

```powershell
# Validate a config file
powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.local.test.json

# Exit code 0 = pass, 1 = fail (useful for scripting)
if ($LASTEXITCODE -eq 0) { "Config is valid" }
```
