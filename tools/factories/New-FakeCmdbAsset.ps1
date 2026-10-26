#Requires -Version 7.1

<#
.SYNOPSIS
Creates one synthetic CMDB hardware asset without accessing a service.
.DESCRIPTION
Returns a plain PowerShell object with five descriptive source fields. This is
a demonstration schema inspired by Atlassian Assets concepts, not a vendor SDK
model or API response. Does not write files, correlate devices, or resolve users.
Supply AssetId for repeatable records. Optional fields default to null; supplied
null, empty, and whitespace strings are preserved without trimming or inference.
.PARAMETER AssetId
Stable CMDB record identifier as nonblank text. Defaults to a new GUID string.
Opaque: not required to be a GUID, asset tag, serial number, or Intune device ID.
Retain this value when editing an asset or building future investigation links.
.PARAMETER AssetTag
Inventory label as a string or null. Defaults to null. Separate from AssetId.
.PARAMETER DeviceName
Recorded hostname as a string or null. Defaults to null. No name is generated.
.PARAMETER SerialNumber
Recorded manufacturer serial number as a string or null. Defaults to null.
No serial number is inferred from AssetId, AssetTag, or DeviceName.
.PARAMETER AssignedUserReference
Opaque CMDB person reference as a string or null. Defaults to null. It is not
assumed to be an Entra user ID, UPN, email address, or resolved identity.
.INPUTS
None

Pipeline input is not accepted.
.OUTPUTS
System.Management.Automation.PSCustomObject

One object with assetId, assetTag, deviceName, serialNumber, assignedUserReference
in that order. All non-null values are strings. Invalid types and null, empty,
or whitespace-only AssetId values raise terminating errors.
.EXAMPLE
$parameters = @{
    AssetId = 'CMDB-ASSET-001'
    DeviceName = 'SYNTH-ASSIGNED-001'
    SerialNumber = 'SYNTH-000001'
    AssignedUserReference = 'CMDB-PERSON-001'
}
./tools/factories/New-FakeCmdbAsset.ps1 @parameters
Creates a repeatable source record without assuming any user identity mapping.
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [AllowNull()]
    [AllowEmptyString()]
    $AssetId = (New-Guid).ToString(),

    [AllowNull()]
    [AllowEmptyString()]
    $AssetTag = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $DeviceName = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $SerialNumber = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $AssignedUserReference = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$properties = [ordered]@{
    assetId = $AssetId
    assetTag = $AssetTag
    deviceName = $DeviceName
    serialNumber = $SerialNumber
    assignedUserReference = $AssignedUserReference
}

foreach ($propertyName in $properties.Keys) {
    $value = $properties[$propertyName]
    if ($null -ne $value -and $value -isnot [string]) {
        throw "$propertyName must be a string or null."
    }
}
if ($null -eq $AssetId -or $AssetId.Trim() -eq '') {
    throw 'assetId must be a nonblank string.'
}

[pscustomobject] $properties
