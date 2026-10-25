#Requires -Version 7.0

<#
.SYNOPSIS
Lists, saves, or deletes saved PSU Git configurations through the Management API.
.DESCRIPTION
Requires a PSU app token authorized for the requested operation. Returns PSU's
response without filtering fields. API errors terminate the request. Redirects
are disabled; supply the final server URL, including any path prefix.

List uses GET /api/v1/git/settings. Save uses POST to that path. Delete uses
DELETE /api/v1/git/settings/{id}. There is no retrieve-by-ID operation; select
the intended configuration from the list. Names are not checked for duplicates.

Treat saves as complete submissions: retrieve and preserve existing fields before
updating. The tool does not assign, apply, reclone, or request synchronization.
Editing an active configuration can affect the running deployment.
.PARAMETER ComputerName
PSU server URL, starting with http:// or https://. Use HTTPS for remote servers.
.PARAMETER AppToken
Bearer token authorized for the operation. Obtain it from your secret-management
system or an interactive prompt; keep it out of tracked files and logs.
.PARAMETER Id
Positive 64-bit configuration ID. Supply for updates or deletion; omit for creation.
.PARAMETER Name
Configuration label, sent as name.
.PARAMETER Remote
Git remote URL, sent as remote. HTTPS and SSH forms are accepted by the wrapper.
.PARAMETER Branch
Git branch name, sent as branch.
.PARAMETER SyncBehavior
TwoWay, OneWay (pull-only), or PushOnly. Sent as syncBehavior integers 0, 1, or 2.
.PARAMETER Mode
Manual or Automatic. Sent as mode integers 0 or 1.
.PARAMETER Interval
Synchronization interval in seconds, sent as interval.
.PARAMETER ExternalGit
Enables the external Git client. Use -ExternalGit:$false to disable it explicitly.
Sent as the externalGit JSON boolean.
.PARAMETER GitSshKey
String sent as gitSshKey. Consult project errata before selecting an SSH key.
.PARAMETER Settings
Hashtable of API fields. Named parameters override corresponding entries without
modifying the caller's hashtable. Values use API types, including numeric enums,
booleans, and arrays. Unknown fields are sent unchanged for PSU to validate.
Fields in the checked schema include proxyUrl, updateSubmodules, paused,
initBehavior, and gitEnvironmentVariables. Use the instance's Swagger schema.
.PARAMETER Save
Creates or updates a configuration. No Git field defaults are added by the wrapper;
omitted fields are left to PSU's request handling.
.PARAMETER Delete
Deletes the configuration identified by Id.
.INPUTS
None

Pipeline input is not accepted.
.OUTPUTS
System.Object

The unfiltered API response, which may contain credentials. A preview emits no
API response for a skipped write.
.EXAMPLE
$configurations = ./tools/Invoke-GitSettingsApi.ps1 @connection
Lists saved configurations using a hashtable containing ComputerName and AppToken.
.EXAMPLE
./tools/Invoke-GitSettingsApi.ps1 @connection -Save -Settings $settings -Interval 120 -WhatIf
Previews an update using a complete configuration previously retrieved into $settings.
.EXAMPLE
./tools/Invoke-GitSettingsApi.ps1 @connection -Delete -Id 7 -WhatIf
Previews deletion of illustrative configuration 7.
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

    [Parameter(ParameterSetName = 'Save')]
    [Parameter(Mandatory, ParameterSetName = 'Delete')]
    [ValidateRange(1, [int64]::MaxValue)]
    [int64]$Id,

    [Parameter(ParameterSetName = 'Save')]
    [string]$Name,

    [Parameter(ParameterSetName = 'Save')]
    [string]$Remote,

    [Parameter(ParameterSetName = 'Save')]
    [string]$Branch,

    [Parameter(ParameterSetName = 'Save')]
    [ValidateSet('TwoWay', 'OneWay', 'PushOnly')]
    [string]$SyncBehavior,

    [Parameter(ParameterSetName = 'Save')]
    [ValidateSet('Manual', 'Automatic')]
    [string]$Mode,

    [Parameter(ParameterSetName = 'Save')]
    [int]$Interval,

    [Parameter(ParameterSetName = 'Save')]
    [switch]$ExternalGit,

    [Parameter(ParameterSetName = 'Save')]
    [string]$GitSshKey,

    [Parameter(ParameterSetName = 'Save')]
    [hashtable]$Settings = @{},

    [Parameter(Mandatory, ParameterSetName = 'Save')]
    [ValidateScript({ $_ -eq $true })]
    [switch]$Save,

    [Parameter(Mandatory, ParameterSetName = 'Delete')]
    [ValidateScript({ $_ -eq $true })]
    [switch]$Delete
)

$request = @{
    Uri = "$($ComputerName.TrimEnd('/'))/api/v1/git/settings"
    Method = 'Get'
    Headers = @{ Authorization = "Bearer $AppToken" }
    MaximumRedirection = 0
    ErrorAction = 'Stop'
}

switch ($PSCmdlet.ParameterSetName) {
    'Save' {
        $payload = @{}
        foreach ($key in $Settings.Keys) {
            $payload[$key] = $Settings[$key]
        }

        $fields = @{
            Id = 'id'
            Name = 'name'
            Remote = 'remote'
            Branch = 'branch'
            SyncBehavior = 'syncBehavior'
            Mode = 'mode'
            Interval = 'interval'
            ExternalGit = 'externalGit'
            GitSshKey = 'gitSshKey'
        }
        foreach ($parameterName in $fields.Keys) {
            if ($PSBoundParameters.ContainsKey($parameterName)) {
                $value = $PSBoundParameters[$parameterName]
                switch ($parameterName) {
                    'SyncBehavior' { $value = @{ TwoWay = 0; OneWay = 1; PushOnly = 2 }[$value] }
                    'Mode' { $value = @{ Manual = 0; Automatic = 1 }[$value] }
                    'ExternalGit' { $value = [bool]$value }
                }
                $payload[$fields[$parameterName]] = $value
            }
        }

        $request.Method = 'Post'
        $request.Body = $payload | ConvertTo-Json -Depth 100 -Compress
    }
    'Delete' {
        $request.Method = 'Delete'
        $request.Uri += "/$Id"
    }
}

if ($request.ContainsKey('Body')) {
    $request.ContentType = 'application/json; charset=utf-8'
}

if ($request.Method -eq 'Get' -or $PSCmdlet.ShouldProcess($request.Uri, "$($request.Method) Git settings")) {
    Invoke-RestMethod @request
}
