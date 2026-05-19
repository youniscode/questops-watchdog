# QuestOps Watchdog — Release Checklist

Steps to create and publish a new release.

---

## Pre-release

- [ ] All changes committed and tested on the working branch
- [ ] QA checklist (qa-checklist.md) fully executed with all checks passing
- [ ] Working tree is clean: `git status` shows no uncommitted changes

## 1. Bump Version

- [ ] Update `VERSION` file to the new version (e.g. `v0.1.23`)
- [ ] Update `CHANGELOG.md`:
  - [ ] Add new entry at the top with version, date, and description of changes
  - [ ] Follow existing format: `## vX.Y.Z — Title (YYYY-MM-DD)`
- [ ] Update `README.md` version badge if present
- [ ] Update `PROJECTMAP.md` current phase and version
- [ ] Commit: `git add VERSION CHANGELOG.md README.md PROJECTMAP.md`
- [ ] Commit message: `release vX.Y.Z`

## 2. Run QA Checklist

- [ ] Execute all sections of `docs/qa-checklist.md`
- [ ] Any failures must be fixed before proceeding

## 3. Package Release

- [ ] Run: `powershell -File scripts\package_release.ps1`
- [ ] Verify output shows correct version and no errors
- [ ] Verify release folder structure:
  ```
  dist/questops-watchdog-vX.Y.Z/
  ├── config/
  ├── scripts/
  ├── lib/
  ├── docs/
  ├── README.md
  ├── CHANGELOG.md
  ├── VERSION
  ├── PROJECTMAP.md
  └── AI_WORKSPACE_RULES.md
  ```

## 4. Inspect Release ZIP

- [ ] Locate ZIP at `dist/questops-watchdog-vX.Y.Z.zip`
- [ ] Verify ZIP opens without corruption
- [ ] Spot-check a config file inside the ZIP
- [ ] Spot-check a script inside the ZIP
- [ ] Confirm excluded items are absent: no `logs/`, `state/`, `dist/`, `.git/`, `*.log`, `__*.json`

## 5. Create Git Tag

- [ ] `git tag -a vX.Y.Z -m "QuestOps Watchdog vX.Y.Z"`
- [ ] `git push origin vX.Y.Z`

## 6. Push Branch

- [ ] `git push origin <branch>`
- [ ] Verify tag appears on GitHub

## 7. GitHub Release (optional)

- [ ] Create GitHub Release from tag vX.Y.Z
- [ ] Title: `QuestOps Watchdog vX.Y.Z`
- [ ] Description: paste relevant CHANGELOG entry
- [ ] Attach: `dist/questops-watchdog-vX.Y.Z.zip`
- [ ] Mark as pre-release if appropriate

## Post-release

- [ ] Update Fiverr gig version references if applicable
- [ ] Update portfolio-summary.md version if applicable
