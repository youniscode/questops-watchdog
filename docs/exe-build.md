# EXE Build Guide

QuestOps Watchdog provides an optional workflow to compile the modern dark-themed GUI Setup Wizard into a standalone Windows executable (`.exe`). This makes it even easier to deliver to clients as a single file.

---

## 1. Requirements

The EXE build is **optional**. The PowerShell version of the wizard (`scripts/setup_client_gui.ps1`) is the official, supported method and does not require any extra tools.

To build the EXE, you must have the **PS2EXE** module installed on your machine.

### Manual Installation
Open a PowerShell terminal as Administrator and run:

```powershell
Install-Module ps2exe -Scope CurrentUser
```

---

## 2. How to Build

Once PS2EXE is installed, you can use the provided build script:

1. Open PowerShell.
2. Navigate to your QuestOps Watchdog folder.
3. Run the build script:

```powershell
powershell -File scripts\build_setup_exe.ps1
```

---

## 3. Outputs

The build script will create a new directory and file:

- **Folder**: `dist/exe/`
- **File**: `dist/exe/QuestOpsWatchdogSetup.exe`

This file is a standalone wrapper around the `setup_client_gui.ps1` script.

---

## 4. Important Warnings

### Antivirus False Positives
Compiling PowerShell scripts into EXEs can sometimes trigger "False Positive" alerts from antivirus software (like Windows Defender). 

- **Internal Use**: If using it yourself, you may need to "Allow" it or add an exclusion.
- **Client Delivery**: We recommend sending the PowerShell version (`.ps1`) to clients unless they specifically request an EXE and understand how to handle antivirus warnings.

### Verification
Always test the generated EXE on a clean machine (or a VM) before sending it to a client. Ensure that:
1. It opens correctly.
2. Buttons like **Auto-Detect** and **Browse** work.
3. It can successfully generate and validate a config.

### Secrets
Never include hardcoded secrets (like Discord Webhook URLs) in the script before building. The wizard is designed to collect these from the user and store them in environment variables.
