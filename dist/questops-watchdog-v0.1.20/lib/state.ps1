function Get-QOStateFilePath {
    <#
    .SYNOPSIS
        Builds the full path to a server's state JSON file.

    .PARAMETER StateRoot
        Root directory for all state files (e.g. ".\state").

    .PARAMETER ServerKey
        Filesystem-safe identifier for the server (e.g. "valheim-01").

    .OUTPUTS
        [string] Full path to the state file.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateRoot,

        [Parameter(Mandatory = $true)]
        [string]$ServerKey
    )

    $path = Join-Path -Path $StateRoot -ChildPath $ServerKey
    $path = Join-Path -Path $path -ChildPath "state.json"
    return $path
}


function Read-QOState {
    <#
    .SYNOPSIS
        Reads a state JSON file from disk. Returns empty hashtable if missing or corrupt.

    .PARAMETER StatePath
        Full path to the state JSON file.

    .OUTPUTS
        [hashtable] Server state, or empty hashtable if file doesn't exist or is invalid.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatePath
    )

    $state = @{}

    try {
        if (-not (Test-Path -LiteralPath $StatePath)) {
            return $state
        }

        $content = Get-Content -LiteralPath $StatePath -Raw -ErrorAction Stop

        if (-not $content) {
            return $state
        }

        $parsed = $content | ConvertFrom-Json -ErrorAction Stop

        if ($parsed -is [PSCustomObject]) {
            foreach ($prop in $parsed.PSObject.Properties) {
                $state[$prop.Name] = $prop.Value
            }
        }
    }
    catch {
        # Return empty state on any error (missing, corrupt, unreadable)
    }

    return $state
}


function Write-QOState {
    <#
    .SYNOPSIS
        Writes a state hashtable to disk as JSON. Creates parent folders if needed.

    .PARAMETER StatePath
        Full path to the state JSON file.

    .PARAMETER State
        Hashtable of alert keys to timestamps.

    .OUTPUTS
        [bool] $true if write succeeded, $false on failure.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    try {
        $dir = Split-Path -Parent $StatePath

        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
        }

        $State | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding UTF8 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Failed to write state file: $StatePath"
        return $false
    }
}


function Test-QOAlertCooldown {
    <#
    .SYNOPSIS
        Checks whether the cooldown period has passed for a given alert key.

    .PARAMETER State
        Hashtable of alert keys to last-sent timestamps.

    .PARAMETER AlertKey
        Unique key for the alert type (e.g. "process_stopped", "log_stale").

    .PARAMETER CooldownMinutes
        Minimum minutes between repeated alerts of this type.

    .OUTPUTS
        [hashtable] Returns @{ CanSend; Message }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$AlertKey,

        [Parameter(Mandatory = $true)]
        [int]$CooldownMinutes
    )

    $result = @{
        CanSend = $true
        Message = ""
    }

    try {
        if ($State.ContainsKey($AlertKey)) {
            $lastSent = $State[$AlertKey]

            if ($lastSent -is [string]) {
                $lastSent = [DateTime]::Parse($lastSent)
            }

            $elapsed = [DateTime]::UtcNow - $lastSent

            if ($elapsed.TotalMinutes -lt $CooldownMinutes) {
                $remaining = [math]::Round($CooldownMinutes - $elapsed.TotalMinutes, 1)
                $result.CanSend = $false
                $result.Message = "Cooldown active for '$AlertKey' ($remaining min remaining)."
                return $result
            }
        }

        $result.Message = "Cooldown passed for '$AlertKey'."
    }
    catch {
        $result.Message = "Could not check cooldown for '$AlertKey'."
    }

    return $result
}


function Set-QOAlertSent {
    <#
    .SYNOPSIS
        Records that an alert was just sent by updating the state with the current UTC timestamp.

    .PARAMETER State
        Hashtable of alert keys to timestamps (modified in place).

    .PARAMETER AlertKey
        Unique key for the alert type (e.g. "process_stopped").

    .OUTPUTS
        [hashtable] The updated state hashtable.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$AlertKey
    )

    $State[$AlertKey] = [DateTime]::UtcNow.ToString("o")
    return $State
}


function Set-QOAlertActive {
    <#
    .SYNOPSIS
        Marks an alert key as actively failing in state. Used by recovery alert logic.

    .PARAMETER State
        Hashtable containing active_failures array.

    .PARAMETER AlertKey
        Unique key for the alert type (e.g. "process_stopped").

    .OUTPUTS
        [hashtable] The updated state hashtable.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$AlertKey
    )

    $failures = @()
    if ($State.ContainsKey("active_failures") -and $State["active_failures"]) {
        $failures = $State["active_failures"]
    }
    if ($failures -notcontains $AlertKey) {
        $failures += $AlertKey
    }
    $State["active_failures"] = $failures
    return $State
}


function Clear-QOAlertActive {
    <#
    .SYNOPSIS
        Removes an alert key from the active failures list (recovery sent or condition resolved).

    .PARAMETER State
        Hashtable containing active_failures array.

    .PARAMETER AlertKey
        Unique key for the alert type (e.g. "process_stopped").

    .OUTPUTS
        [hashtable] The updated state hashtable.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$AlertKey
    )

    if ($State.ContainsKey("active_failures") -and $State["active_failures"]) {
        $failures = @($State["active_failures"]) | Where-Object { $_ -ne $AlertKey }
        if ($failures) {
            $State["active_failures"] = @($failures)
        }
        else {
            $State.Remove("active_failures")
        }
    }
    return $State
}


function Test-QOAlertActive {
    <#
    .SYNOPSIS
        Checks whether an alert key is currently marked as actively failing.

    .PARAMETER State
        Hashtable containing active_failures array.

    .PARAMETER AlertKey
        Unique key for the alert type (e.g. "process_stopped").

    .OUTPUTS
        [bool] $true if the alert key is in the active failures list.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$AlertKey
    )

    if (-not $State.ContainsKey("active_failures") -or -not $State["active_failures"]) {
        return $false
    }
    $failures = @($State["active_failures"])
    return ($failures -contains $AlertKey)
}
