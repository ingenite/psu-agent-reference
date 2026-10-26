#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Users'; RequiredVersion = '2.41.2' }

<#
.SYNOPSIS
Exports supplied synthetic Entra user SDK models to a five-column CSV.
.DESCRIPTION
Replaces the destination unless -Append is supplied. Defaults to data/entra-users.csv
in this repository. Buffers and validates all input before writing. Creates parent
directories when needed. Retains order and duplicate IDs without identity inference.
Only the selected source fields are exported; additional model properties are ignored.
Null and empty strings both become empty CSV cells; whitespace is preserved.
AccountEnabled is True, False, or an empty cell for null. CSV contains strings,
not SDK types: restoration must explicitly parse nonempty Boolean cells, rather
than casting strings to bool (a nonempty 'False' string casts to true).
.PARAMETER InputObject
One or more Graph user SDK models, as an array or pipeline input. Each must satisfy
the five source-field constraints in New-FakeEntraUser.ps1. Nulls, non-models, empty
input, and invalid source values terminate before writing. No input objects change.
.PARAMETER Path
Literal destination path. Defaults to data/entra-users.csv in this repository.
.PARAMETER Append
Appends without deduplication; creates a missing file. An existing nonempty file
must have exactly id,displayName,userPrincipalName,mail,accountEnabled in that order.
Incompatible headers terminate before writing, including headers missing columns.
.INPUTS
Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser

User SDK models to export.
.OUTPUTS
None

Writes UTF-8 CSV columns id,displayName,userPrincipalName,mail,accountEnabled.
Invalid input leaves the destination unchanged. Filesystem failures terminate;
writing is not an atomic file replacement.
.EXAMPLE
./tools/factories/New-FakeEntraUser.ps1 -DisplayName 'Alex Example' |
    ./tools/factories/Export-FakeEntraUser.ps1 -Path ./tools/output/example-users.csv
Creates and exports one user, replacing the example CSV.
.EXAMPLE
$users | ./tools/factories/Export-FakeEntraUser.ps1 -Path ./tools/output/example-users.csv -Append
Appends supplied source models to the example CSV.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [object[]] $InputObject,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_.Trim() -ne '' })]
    [string] $Path = (Join-Path $PSScriptRoot '../../data/entra-users.csv'),

    [switch] $Append
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $records = @()
    $columns = @('id', 'displayName', 'userPrincipalName', 'mail', 'accountEnabled')
    $factoryPath = Join-Path $PSScriptRoot 'New-FakeEntraUser.ps1'
}

process {
    if ($null -eq $InputObject) {
        throw 'InputObject must contain Graph user models, not null.'
    }
    foreach ($user in $InputObject) {
        if ($user -isnot [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]) {
            throw 'InputObject must contain Graph user models.'
        }
        $properties = [ordered]@{}
        foreach ($column in $columns) {
            $properties[$column] = $user.$column
        }
        $null = & $factoryPath @properties
        $records += [pscustomobject] $properties
    }
}

end {
    if ($records.Count -eq 0) {
        throw 'Provide at least one Graph user model to export.'
    }
    if ($Append -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $header = Get-Content -LiteralPath $Path -TotalCount 1
        if ($header) {
            # Parse only the header plus a dummy row, including header-only files.
            $headerRecord = @($header, 'header-check') | ConvertFrom-Csv
            if (($headerRecord.PSObject.Properties.Name -join ',') -cne ($columns -join ',')) {
                throw 'Existing CSV header is incompatible with the five Entra user columns.'
            }
        }
    }

    $parentDirectory = Split-Path -Path $Path -Parent
    if ($parentDirectory) {
        New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
    }
    $records | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8 -Append:$Append
}
