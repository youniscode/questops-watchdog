function Send-QODiscordWebhook {
    <#
    .SYNOPSIS
        Sends a Discord embed alert via webhook.

    .PARAMETER WebhookUrl
        The Discord webhook URL. Never log or print this value.

    .PARAMETER Title
        Embed title (e.g. "Server Process Stopped").

    .PARAMETER Description
        Embed body text describing the issue.

    .PARAMETER Severity
        One of: info, warning, critical, success.
        Maps to embed color: blue, orange, red, green.

    .PARAMETER ServerName
        Name of the server this alert is about.

    .OUTPUTS
        [bool] Returns $true if the webhook was sent successfully, $false on failure.
    #>

    param(
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidateSet('info', 'warning', 'critical', 'success')]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )

    # Map severity to Discord embed decimal colour
    $colorMap = @{
        info     = 5814783   # blue
        warning  = 16763904  # orange
        critical = 15548997  # red
        success  = 5763719   # green
    }
    $color = $colorMap[$Severity]

    # Build the embed payload
    $embed = @{
        title       = $Title
        description = $Description
        color       = $color
        fields      = @(
            @{ name = "Server";  value = $ServerName; inline = $true }
            @{ name = "Severity"; value = $Severity;   inline = $true }
        )
        timestamp   = [DateTime]::UtcNow.ToString("o")
    }

    $body = @{ embeds = @($embed) } | ConvertTo-Json -Depth 4

    try {
        $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Discord webhook failed. (hidden URL for security)"
        return $false
    }
}
