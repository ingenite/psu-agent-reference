#Requires -Version 7.0

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
