#Requires -Version 7.0

<#
.SYNOPSIS
Lists, retrieves, creates, renames, or deletes PSU SSH keys through the Management API.
.DESCRIPTION
Requires a PSU app token authorized for the requested operation. Returns PSU's
response without filtering fields. Responses can contain key material; select
needed fields before displaying or logging them. API errors terminate the request.
Redirects are disabled; supply the final server URL, including any path prefix.

List and retrieve use GET /api/v1/sshkey and /api/v1/sshkey/{id}. Create uses POST
with name. Rename uses PUT with id and name. Delete uses DELETE with the ID in
the URL. Conflicting operations are rejected by parameter sets.

The tool manages PSU keys. Git-host registration, Git settings, and repository
activation are separate operations.
.PARAMETER ComputerName
PSU server URL, starting with http:// or https://. Use HTTPS for remote servers.
.PARAMETER AppToken
Bearer token authorized for the operation. Obtain it from your secret-management
system or an interactive prompt; keep it out of tracked files and logs.
.PARAMETER Id
Positive 64-bit key ID. Optional for reads; required for rename and deletion.
Capture the ID returned by creation for subsequent operations.
.PARAMETER Name
Nonempty key label. Required for creation and rename.
.PARAMETER Create
Creates a PSU key with the supplied Name.
.PARAMETER Update
Renames the key identified by Id to the supplied Name.
.PARAMETER Delete
Deletes the key identified by Id.
.INPUTS
None

Pipeline input is not accepted.
.OUTPUTS
System.Object

The unfiltered API response, potentially containing key material. A preview emits
no API response for a skipped write.
.EXAMPLE
$keys = ./tools/Invoke-SshKeyApi.ps1 @connection
Lists keys using a hashtable containing ComputerName and AppToken.
.EXAMPLE
$key = ./tools/Invoke-SshKeyApi.ps1 @connection -Id 7
Retrieves illustrative key 7.
.EXAMPLE
./tools/Invoke-SshKeyApi.ps1 @connection -Create -Name 'github-deploy' -WhatIf
Previews creation. Capture the response when running an authorized creation.
.EXAMPLE
./tools/Invoke-SshKeyApi.ps1 @connection -Update -Id 7 -Name 'production' -WhatIf
Previews renaming illustrative key 7.
.EXAMPLE
./tools/Invoke-SshKeyApi.ps1 @connection -Delete -Id 7 -WhatIf
Previews deletion of illustrative key 7.
.NOTES
WhatIf skips writes; reads still execute and require authentication. Confirm
requests confirmation for a write. The tool adds no authorization model.
#>
[CmdletBinding(DefaultParameterSetName = 'Read', SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https?://')]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AppToken,

    [Parameter(ParameterSetName = 'Read')]
    [Parameter(Mandatory, ParameterSetName = 'Update')]
    [Parameter(Mandatory, ParameterSetName = 'Delete')]
    [ValidateRange(1, [int64]::MaxValue)]
    [int64]$Id,

    [Parameter(Mandatory, ParameterSetName = 'Create')]
    [Parameter(Mandatory, ParameterSetName = 'Update')]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory, ParameterSetName = 'Create')]
    [ValidateScript({ $_ -eq $true })]
    [switch]$Create,

    [Parameter(Mandatory, ParameterSetName = 'Update')]
    [ValidateScript({ $_ -eq $true })]
    [switch]$Update,

    [Parameter(Mandatory, ParameterSetName = 'Delete')]
    [ValidateScript({ $_ -eq $true })]
    [switch]$Delete
)

$request = @{
    Uri = "$($ComputerName.TrimEnd('/'))/api/v1/sshkey"
    Method = 'Get'
    Headers = @{ Authorization = "Bearer $AppToken" }
    MaximumRedirection = 0
    ErrorAction = 'Stop'
}

switch ($PSCmdlet.ParameterSetName) {
    'Read' {
        if ($PSBoundParameters.ContainsKey('Id')) {
            $request.Uri += "/$Id"
        }
    }
    'Create' {
        $request.Method = 'Post'
        $request.Body = @{ name = $Name } | ConvertTo-Json -Compress
    }
    'Update' {
        $request.Method = 'Put'
        $request.Body = @{ id = $Id; name = $Name } | ConvertTo-Json -Compress
    }
    'Delete' {
        $request.Method = 'Delete'
        $request.Uri += "/$Id"
    }
}

if ($request.ContainsKey('Body')) {
    $request.ContentType = 'application/json; charset=utf-8'
}

if ($request.Method -eq 'Get' -or $PSCmdlet.ShouldProcess($request.Uri, "$($request.Method) SSH key")) {
    Invoke-RestMethod @request
}
