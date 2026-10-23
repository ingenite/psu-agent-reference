#Requires -Version 7.0

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
