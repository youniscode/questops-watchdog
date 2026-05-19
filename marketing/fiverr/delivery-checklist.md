# Delivery Checklist

## For every order

- [ ] QuestOps Watchdog installed and tested on the buyer's machine
- [ ] Discord webhook URL configured as environment variable
- [ ] Discord webhook test message sent and confirmed received
- [ ] Config validated with validate_config.ps1 (zero failures)
- [ ] Manual run completed: console output reviewed, no unexpected errors
- [ ] All check types working: process, disk, log, backup (as applicable)
- [ ] Console output reviewed with buyer and explained

## Standard package additions

- [ ] Multiple servers configured (up to 3)
- [ ] Log and backup freshness checks enabled per server
- [ ] Summary embed configured and tested (if buyer has Discord webhook)
- [ ] Maintenance mode documented with flag-file instructions
- [ ] Cooldown thresholds tuned per server
- [ ] Validation hardening applied (type safety, placeholder detection)
- [ ] Scheduled task installed and tested
- [ ] Buyer shown how to start/stop the task

## Premium package additions

- [ ] Up to 6 servers configured
- [ ] Recovery alerts configured and tested (simulate failure + recovery)
- [ ] Clean release ZIP generated with package_release.ps1
- [ ] All thresholds, paths, and alert rules documented
- [ ] Operations review completed with written recommendations
- [ ] Architecture explained: config, validator, runner, state, logs, alerts
- [ ] Buyer can edit config independently after delivery

## Deliverable files

- Configured watchdog installation (live on buyer's machine)
- Release ZIP with all product files (downloadable)
- Config files with buyer's server paths and settings
- Written summary of what was configured and where
- Quick reference: commands for manual run, validation, maintenance toggle

## Not delivered

- Cloud accounts or subscriptions
- Web dashboard or mobile app
- Server restart or auto-healing scripts
- Ongoing monitoring or 24/7 support
- Game server installation or mod configuration
