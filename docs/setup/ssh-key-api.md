# Manage PSU SSH keys

## Synopsis

`tools/Invoke-SshKeyApi.ps1` lists, retrieves, creates, renames, and deletes keys
through PSU's Management API. Git-host registration and deployment configuration
are separate operations.

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
$keys = ./tools/Invoke-SshKeyApi.ps1 @connection
$key = ./tools/Invoke-SshKeyApi.ps1 @connection -Id 7
```

For unattended use, obtain the token from your deployment's secret-management
system. Keep tokens and key material out of tracked files and logs. Responses can
contain key material; select the fields needed before displaying or recording them.

## Examples

Preview creation before an authorized write:

```powershell
./tools/Invoke-SshKeyApi.ps1 @connection -Create -Name 'github-deploy' -WhatIf
```

After creation, capture the response and use its returned ID for subsequent
operations. ID `7` below is illustrative:

```powershell
./tools/Invoke-SshKeyApi.ps1 @connection -Update -Id 7 -Name 'production' -WhatIf
./tools/Invoke-SshKeyApi.ps1 @connection -Delete -Id 7 -WhatIf
```

## Git synchronization

For GitHub SSH access, register the PSU key's public key as a read-only repository
deploy key. Keep the private key on the PSU side. Configure the external Git
client, SSH remote, key selection, and pull-only behavior separately. Consult
errata for the unresolved key-reference mapping and deployment verification gaps.

## Reference and verification

```powershell
Get-Help ./tools/Invoke-SshKeyApi.ps1 -Full
Invoke-Pester -Path ./tools/Invoke-SshKeyApi.Tests.ps1 -Output Detailed
```

Command help owns parameter details, API mappings, and preview behavior. Use your
instance's `/swagger/index.html` for version-specific schemas and confirm that
the token permits the requested operation. The sibling tests exercise request
construction and response handling with mocked HTTP calls.
