#Requires -Version 7.1

<#
.SYNOPSIS
Exports supplied synthetic CMDB assets to a five-column CSV.
.DESCRIPTION
Replaces the destination CSV unless -Append is supplied. Defaults to
data/cmdb-assets.csv in this repository. Append adds rows without deduplication.
Writes UTF-8 CSV, creating its parent directory when needed. An incompatible
existing append header is rejected by Export-Csv.
Validates and buffers all input before writing. Each object must expose
the five source properties documented by New-FakeCmdbAsset.ps1, with the same
value constraints. Additional properties are ignored. No input objects change.
Preserves input order, supplied identifiers, and duplicate values without
deduplication or correlation. Null and empty strings both become empty CSV cells;
whitespace remains whitespace. CSV does not preserve PowerShell object types.
This exporter does not retrieve records, map identities, or generate report fields.
.PARAMETER InputObject
One or more compatible source objects, supplied as an array or through the
pipeline. Null objects, missing properties, invalid values, and empty input are
rejected with terminating errors before writing to the destination.
.PARAMETER Path
Literal destination file path. Defaults to data/cmdb-assets.csv relative to this
repository. The path is interpreted literally.
.PARAMETER Append
Retains existing rows and appends new ones without deduplicating IDs. Creates a
missing file. Without this switch, the destination is replaced.
.INPUTS
System.Object[]

CMDB source objects containing the factory's five properties.
.OUTPUTS
None

Writes columns assetId, assetTag, deviceName, serialNumber, assignedUserReference
in that order. Invalid input leaves an existing destination unchanged. Filesystem
write failures terminate; writing is not an atomic file replacement.
.EXAMPLE
./tools/factories/New-FakeCmdbAsset.ps1 -AssetId CMDB-ASSET-001 |
    ./tools/factories/Export-FakeCmdbAsset.ps1 -Path ./tools/output/example-assets.csv
Exports one source record from the repository root.
.EXAMPLE
$assets | ./tools/factories/Export-FakeCmdbAsset.ps1 -Path ./tools/output/example-assets.csv -Append
Appends supplied CMDB source objects to the example file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [object[]] $InputObject,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_.Trim() -ne '' })]
    [string] $Path = (Join-Path $PSScriptRoot '../../data/cmdb-assets.csv'),

    [switch] $Append
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $records = @()
    $columns = @('assetId', 'assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')
    $factoryPath = Join-Path $PSScriptRoot 'New-FakeCmdbAsset.ps1'
}

process {
    if ($null -eq $InputObject) {
        throw 'InputObject must contain CMDB source objects, not null.'
    }
    foreach ($asset in $InputObject) {
        if ($null -eq $asset) {
            throw 'InputObject must contain CMDB source objects, not null.'
        }

        $parameters = @{}
        foreach ($column in $columns) {
            if ($column -notin $asset.PSObject.Properties.Name) {
                throw "InputObject is missing CMDB source property '$column'."
            }
            $parameters[$column] = $asset.$column
        }
        $records += & $factoryPath @parameters
    }
}

end {
    if ($records.Count -eq 0) {
        throw 'Provide at least one CMDB source object to export.'
    }

    $parentDirectory = Split-Path -Path $Path -Parent
    if ($parentDirectory) {
        New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
    }

    $records | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8 -Append:$Append
}
