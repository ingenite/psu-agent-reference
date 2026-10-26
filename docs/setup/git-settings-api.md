# Manage saved PSU Git settings

## Synopsis

`tools/Invoke-GitSettingsApi.ps1` lists, saves, and deletes configurations through
PSU's Management API. Use it to prepare settings for a deployment or update an
existing configuration while preserving its other fields.

## Requirements

Use PowerShell 7 and a PSU app token authorized for the operation. The tool has
no Universal-module or vault dependency. Use HTTPS for remote servers and supply
the final server URL, including any path prefix; redirects are disabled.

From the repository root:

```powershell
$connection = @{
    ComputerName = 'https://psu.example.com'
    AppToken = Read-Host 'PSU app token' -AsSecureString | ConvertFrom-SecureString -AsPlainText
}
$configurations = ./tools/Invoke-GitSettingsApi.ps1 @connection
```

For unattended use, obtain the token from your deployment's secret-management
system. Keep tokens, Git credentials, and credential-bearing responses out of
tracked files and logs.

## Create settings

This previews a pull-only configuration for a public repository that permits
anonymous HTTPS reads:

```powershell
$configuration = @{
    Name = 'production'
    Remote = 'https://github.com/example/psu-config.git'
    Branch = 'main'
    SyncBehavior = 'OneWay'
    Mode = 'Automatic'
    Interval = 60
}
./tools/Invoke-GitSettingsApi.ps1 @connection -Save @configuration -WhatIf
```

Remove `-WhatIf` only when authorized to save. Saving settings is separate from
assigning or applying a configuration. Editing settings already in use can affect
the running deployment. PSU's Apply operation replaces repository files; follow
the project's deployment boundary before making runtime changes.

## Update settings

Treat a save as a complete configuration submission. Retrieve the existing
configuration, preserve its fields, and override only the intended values:

```powershell
$configurations = ./tools/Invoke-GitSettingsApi.ps1 @connection
$settings = $configurations |
    Where-Object id -EQ 7 |
    ConvertTo-Json -Depth 100 |
    ConvertFrom-Json -AsHashtable

if (-not $settings -or $settings.id -ne 7) {
    throw 'Expected Git configuration 7 was not found.'
}

./tools/Invoke-GitSettingsApi.ps1 @connection -Save -Settings $settings -Interval 120 -WhatIf
```

ID `7` is illustrative. The API is not documented as a partial update; omitted
fields may be reset. The wrapper cannot recover credentials omitted or masked
in a response. Supply required secret values separately before resubmitting.

## SSH deployments

SSH requires a PSU key, registration of its public key with the Git host, and
separate configuration of PSU's external Git client and key selection. The client
must be installed and usable by the PSU service account. Check the errata before
choosing this path; it records the unresolved key-reference mapping.
