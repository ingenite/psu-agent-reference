# Manage PSU SSH keys

[Invoke-SshKeyApi.ps1](../../tools/Invoke-SshKeyApi.ps1) lists, retrieves, creates,
renames, and deletes SSH keys through the PSU Management API. It requires
PowerShell 7 and a PSU app token authorized for the requested operation. It has
no Universal-module or vault dependency.

Run the examples from this repository's root. Replace the server URL and obtain
an app token for your PSU deployment:

```powershell
$connection = @{
    ComputerName = 'https://psu.example.com'
    AppToken = Read-Host 'PSU app token' -AsSecureString | ConvertFrom-SecureString -AsPlainText
}

# List keys, or retrieve a particular key by ID.
$keys = ./tools/Invoke-SshKeyApi.ps1 @connection
$key = ./tools/Invoke-SshKeyApi.ps1 @connection -Id 7
```

For unattended use, retrieve the token from your deployment's secret-management
system instead of prompting. Keep tokens out of tracked files, command literals,
and logs. Use HTTPS for remote servers. The script sends a bearer header and
does not follow redirects; supply the final PSU URL, including any path prefix.

## Operations

`ComputerName` and `AppToken` are required for every operation. Four parameter
sets determine the HTTP method and request body:

| Operation | Parameters | API request |
| --- | --- | --- |
| List | No operation parameters | `GET /api/v1/sshkey` |
| Retrieve | `-Id 7` | `GET /api/v1/sshkey/7` |
| Create | `-Create -Name 'github-deploy'` | `POST /api/v1/sshkey` with `name` |
| Rename | `-Update -Id 7 -Name 'production'` | `PUT /api/v1/sshkey` with `id` and `name` |
| Delete | `-Delete -Id 7` | `DELETE /api/v1/sshkey/7` |

Parameter sets reject conflicting operations. IDs must be positive and names
must be nonempty. These named parameters cover all request fields in the
PSU 2026.3.0 SSH-key schemas; there is no additional-body hashtable.

Preview a write with `-WhatIf`, then run it without `-WhatIf` when ready:

```powershell
./tools/Invoke-SshKeyApi.ps1 @connection -Create -Name 'github-deploy' -WhatIf
$key = ./tools/Invoke-SshKeyApi.ps1 @connection -Create -Name 'github-deploy'
```

Capture the new key's response and use its returned ID for subsequent operations.
The ID below is illustrative:

```powershell
./tools/Invoke-SshKeyApi.ps1 @connection -Update -Id 7 -Name 'production' -WhatIf
./tools/Invoke-SshKeyApi.ps1 @connection -Delete -Id 7 -WhatIf
```

`-Confirm` requests confirmation for a write. `-WhatIf` skips write requests
entirely, but read requests still execute and need authentication. The script
returns PSU's response without filtering fields or adding a success summary.
Responses can contain key material; select the fields you need before displaying
or logging them. API errors terminate the request and remain visible to callers.

## Using a key for Git synchronization

Creating a key in PSU is separate from registering its public key with a Git host.
For GitHub, register the public key as a read-only repository deploy key. Keep the
private key on the PSU side. Then configure PSU's external Git client, SSH remote,
key selection, and pull-only behavior separately.

This tool manages PSU keys; it does not register deploy keys, assign Git settings,
or activate a repository. It does not restrict the Git host. The deploy-key
example targets GitHub; GitLab and other hosts are outside this guide's supported
scope, but the guidance can be adapted as needed.

## Compatibility and verification

The operation mapping was checked against PSU 2026.3.0's Management API Swagger
schema. Use your instance's `/swagger/index.html` for current request and response
definitions, and verify that your app token permits the operation. The published
vendor documentation does not identify exact permission names for each SSH-key
operation.

The sibling Pester tests mock HTTP calls. They cover routing, JSON payloads,
response preservation, parameter validation, previews, and error propagation.
They do not prove live key creation, storage, rename, deletion, or Git access.

- [PSU Management API](https://docs.devolutions.net/powershell-universal/config/management-api)
- [PSU Git and SSH configuration](https://docs.devolutions.net/powershell-universal/config/git#external-git-client)
- [GitHub deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys)
