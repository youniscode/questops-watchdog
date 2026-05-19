function Test-QOProcessRunning {
    <#
    .SYNOPSIS
        Checks whether a process with the given name is currently running.

    .PARAMETER ProcessName
        Process name without extension (e.g. "valheim_server", not "valheim_server.exe").

    .OUTPUTS
        [hashtable] Returns @{ Success; Running; Message }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $result = @{
        Success = $false
        Running = $false
        Message = ""
    }

    try {
        $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

        if ($proc) {
            $result.Running = $true
            $result.Message = "Process '$ProcessName' is running."
        }
        else {
            $result.Message = "Process '$ProcessName' is not running."
        }

        $result.Success = $true
    }
    catch {
        $result.Message = "Could not check process '$ProcessName'."
    }

    return $result
}


function Test-QOLogFreshness {
    <#
    .SYNOPSIS
        Checks whether the newest log file in a directory was written within MaxAgeMinutes.

    .PARAMETER Path
        Directory path containing log files.

    .PARAMETER MaxAgeMinutes
        Maximum allowed age of the newest file in minutes.

    .OUTPUTS
        [hashtable] Returns @{ Success; Fresh; AgeMinutes; Message }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int]$MaxAgeMinutes
    )

    $result = @{
        Success     = $false
        Fresh       = $false
        AgeMinutes  = 0
        Message     = ""
    }

    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            $result.Message = "Log path does not exist: $Path"
            $result.Success = $true
            return $result
        }

        $newest = Get-ChildItem -LiteralPath $Path -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        if (-not $newest) {
            $result.Message = "No log files found in: $Path"
            $result.Success = $true
            return $result
        }

        $age = (Get-Date) - $newest.LastWriteTime
        $result.AgeMinutes = [math]::Round($age.TotalMinutes, 1)

        if ($age.TotalMinutes -le $MaxAgeMinutes) {
            $result.Fresh = $true
            $result.Message = "Log is fresh (last modified $($result.AgeMinutes) min ago, limit $MaxAgeMinutes min)."
        }
        else {
            $result.Message = "Log is stale (last modified $($result.AgeMinutes) min ago, limit $MaxAgeMinutes min)."
        }

        $result.Success = $true
    }
    catch {
        $result.Message = "Could not check log freshness for: $Path"
    }

    return $result
}


function Test-QOBackupFreshness {
    <#
    .SYNOPSIS
        Checks whether the newest file or folder in a backup directory was created within MaxAgeHours.

    .PARAMETER Path
        Directory path containing backups.

    .PARAMETER MaxAgeHours
        Maximum allowed age of the newest item in hours.

    .OUTPUTS
        [hashtable] Returns @{ Success; Fresh; AgeHours; Message }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int]$MaxAgeHours
    )

    $result = @{
        Success   = $false
        Fresh     = $false
        AgeHours  = 0
        Message   = ""
    }

    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            $result.Message = "Backup path does not exist: $Path"
            $result.Success = $true
            return $result
        }

        $newest = Get-ChildItem -LiteralPath $Path | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        if (-not $newest) {
            $result.Message = "No backup files or folders found in: $Path"
            $result.Success = $true
            return $result
        }

        $age = (Get-Date) - $newest.LastWriteTime
        $result.AgeHours = [math]::Round($age.TotalHours, 1)

        if ($age.TotalHours -le $MaxAgeHours) {
            $result.Fresh = $true
            $result.Message = "Backup is fresh (last modified $($result.AgeHours) hr ago, limit $MaxAgeHours hr)."
        }
        else {
            $result.Message = "Backup is stale (last modified $($result.AgeHours) hr ago, limit $MaxAgeHours hr)."
        }

        $result.Success = $true
    }
    catch {
        $result.Message = "Could not check backup freshness for: $Path"
    }

    return $result
}


function Test-QODiskSpace {
    <#
    .SYNOPSIS
        Checks whether a drive has at least MinimumFreeGB of free space.

    .PARAMETER DriveLetter
        Drive letter, with or without colon or trailing slash (e.g. "C", "C:", "C:\").

    .PARAMETER MinimumFreeGB
        Minimum free space in gigabytes.

    .OUTPUTS
        [hashtable] Returns @{ Success; Healthy; FreeGB; Message }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [int]$MinimumFreeGB
    )

    $result = @{
        Success = $false
        Healthy = $false
        FreeGB  = 0
        Message = ""
    }

    try {
        $letter = $DriveLetter.Trim(':').Trim('\').Trim('/')
        $drive = Get-PSDrive -Name $letter -ErrorAction Stop

        if ($drive.Free -eq $null) {
            $result.Message = "Drive '$DriveLetter' is not a file system drive."
            $result.Success = $true
            return $result
        }

        $result.FreeGB = [math]::Round($drive.Free / 1GB, 2)

        if ($result.FreeGB -ge $MinimumFreeGB) {
            $result.Healthy = $true
            $result.Message = "Disk $DriveLetter has $($result.FreeGB) GB free (minimum $MinimumFreeGB GB)."
        }
        else {
            $result.Message = "Disk $DriveLetter is low: $($result.FreeGB) GB free (minimum $MinimumFreeGB GB)."
        }

        $result.Success = $true
    }
    catch {
        $result.Message = "Could not check disk space for drive: $DriveLetter"
    }

    return $result
}
