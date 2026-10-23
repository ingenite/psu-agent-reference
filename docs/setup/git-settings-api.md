# Manage saved PSU Git settings

[Invoke-GitSettingsApi.ps1](../../tools/Invoke-GitSettingsApi.ps1) lists, saves,
and deletes Git configurations through the PSU Management API. It requires
PowerShell 7 and a PSU app token authorized for the requested operation. Like the
[SSH key API tool](ssh-key-api.md), it has no Universal-module or vault dependency.

Run the examples from this repository's root. Replace the URL and repository
details with values for your deployment:

```powershell
$connection = @{
    ComputerName = 'https://psu.example.com'
    AppToken = Read-Host 'PSU app token' -AsSecureString | ConvertFrom-SecureString -AsPlainText
}

$configurations = ./tools/Invoke-GitSettingsApi.ps1 @connection
```

For unattended use, retrieve the app token from your deployment's secret-management
system. Keep app tokens, Git credentials, and responses containing credentials out
of tracked files and logs. Use HTTPS for remote servers. Redirects are disabled;
supply the final PSU URL, including any path prefix.

## Operations

`ComputerName` and `AppToken` are required for every operation. Three parameter
sets follow the API's operations:

| Operation | Parameters | API request |
| --- | --- | --- |
| List | No operation parameters | `GET /api/v1/git/settings` |
| Create or update | `-Save`, optional named fields and `-Settings` | `POST /api/v1/git/settings` |
| Delete | `-Delete -Id 7` | `DELETE /api/v1/git/settings/7` |

There is no retrieve-by-ID endpoint. Select the desired configuration from the
list. A save with an existing configuration's ID represents an update; omit the
ID when creating a configuration. The wrapper does not look up names or check for
duplicates. Named IDs must be positive.

Common save fields have named parameters:

| Parameter | Request field | Value |
| --- | --- | --- |
| `Id` | `id` | Existing configuration's 64-bit ID |
| `Name` | `name` | Configuration label |
| `Remote` | `remote` | Git remote; HTTPS and SSH forms are accepted |
| `Branch` | `branch` | Branch name |
| `SyncBehavior` | `syncBehavior` | `TwoWay`, `OneWay`, or `PushOnly` |
| `Mode` | `mode` | `Manual` or `Automatic` |
| `Interval` | `interval` | Integer interval in seconds |
| `ExternalGit` | `externalGit` | Switch; use `-ExternalGit:$false` to disable |
| `GitSshKey` | `gitSshKey` | SSH key reference string expected by PSU |

The named enum values are converted to the API's integers: `TwoWay=0`, `OneWay=1`,
`PushOnly=2`; `Manual=0`, `Automatic=1`. The wrapper sets no defaults for Git
fields. Omitted fields are left to PSU's request handling.

## Create and update

For a public GitHub repository that permits anonymous HTTPS reads, this example
previews a pull-only configuration. Remove `WhatIf` when ready to save:

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

Use `Settings` for other request fields, or for a complete configuration obtained
from the API. It accepts API field names and values without a wrapper-maintained
allowlist. Named parameters override matching fields in the hashtable. The caller's
hashtable is not modified. For example, add `-Settings @{ updateSubmodules = $true }`
to the save above.

Treat a save as a complete configuration submission. The API is not documented as
a partial update, so a body containing only an ID and a changed field may reset
omitted fields. To update, retrieve the current configuration as a hashtable,
preserve its other fields, then override the intended values:

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
./tools/Invoke-GitSettingsApi.ps1 @connection -Delete -Id 7 -WhatIf
```

ID `7` is illustrative. Review credential fields before resubmitting a response:
the wrapper does not recover credentials that PSU omits or masks. Supply any
required secret values from your secret-management system.

Values inside `Settings` use API types, including numeric enums, JSON booleans,
and string arrays. Useful additional fields in PSU 2026.3.0 include `proxyUrl`,
`updateSubmodules`, `paused`, `initBehavior`, and `gitEnvironmentVariables`.
Unknown fields are sent unchanged; PSU decides which fields and values it accepts.
Consult your instance's Swagger schema before using fields from a different version.

`-Confirm` requests confirmation for a write. `-WhatIf` skips write requests, but
reads still execute and require authentication. PSU's response is returned without
filtering fields or adding a success summary. API errors terminate the request and
remain visible to callers.

## SSH and activation

For GitHub SSH access, create a PSU key with the [SSH key API tool](ssh-key-api.md)
and register its public key as a read-only repository deploy key. Saving Git
settings for SSH requires an SSH remote, `-ExternalGit`, and the appropriate
`-GitSshKey` reference. The external Git client must be installed and usable by the
PSU service account; it does not use PSU's configured username/password/PAT fields.

The API declares `gitSshKey` as a string but does not document how that value maps
to the SSH-key response. This mapping has not been verified. Do not assume that a
key's name or numeric ID is the expected reference; verify it for your deployment,
for example against an existing working configuration.

This tool handles saved Git settings. It does not assign settings to a computer,
apply a repository, reclone, or request synchronization. Saving is not proof of
activation or Git connectivity. Editing a configuration already in use may affect
the running deployment; plan those changes accordingly. PSU documents Apply as a
separate operation that replaces repository files and clones the selected remote.

The examples target GitHub. GitLab and other platforms are outside this guide's
supported scope; these resources can be adapted as needed. The wrapper does not
restrict the Git host or synchronization direction.

## Compatibility and verification

The endpoints, field types, and enum values were checked against PSU 2026.3.0's
Management API schema and installed Universal module. Use your instance's
`/swagger/index.html` for version-specific definitions. PSU validates the
configuration and authorizes each operation; the wrapper adds no permission model.

The sibling Pester tests mock HTTP calls and cover request routing, JSON types,
settings overrides, response preservation, parameter validation, previews, and
error propagation. Live read access is checked separately. These checks do not
establish live save/delete behavior, SSH-key selection, activation, or Git access.

- [PSU Management API](https://docs.devolutions.net/powershell-universal/config/management-api)
- [PSU Git configuration](https://docs.devolutions.net/powershell-universal/config/git)
