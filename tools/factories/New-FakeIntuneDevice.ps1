#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.DeviceManagement'; RequiredVersion = '2.41.2' }
<#
.SYNOPSIS
Creates a synthetic Intune managed-device object without connecting to Graph.
.DESCRIPTION
Requires Microsoft.Graph.DeviceManagement 2.41.2. Returns an SDK model without
writing files. Supply identifiers and timestamps for repeatable fixture data.
.EXAMPLE
./New-FakeIntuneDevice.ps1 -DeviceName SYNTH-WIN-001
.EXAMPLE
./New-FakeIntuneDevice.ps1 -DeviceName SYNTH-WIN-001 |
    ./Export-FakeIntuneDevice.ps1 -Path ../../data/intune-devices.csv
#>
[CmdletBinding()]
[OutputType('Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $DeviceName,

    [guid] $Id = (New-Guid),

    [guid] $AzureAdDeviceId = (New-Guid),

    [AllowNull()]
    [AllowEmptyString()]
    $UserId = $null,

    [datetimeoffset] $LastSyncDateTime = (Get-Date -AsUTC),

    [datetimeoffset] $EnrolledDateTime = $LastSyncDateTime.AddDays(-30),

    [ValidateNotNullOrEmpty()]
    [string] $OperatingSystem = 'Windows',

    [ValidateNotNullOrEmpty()]
    [string] $OSVersion = '10.0.26100.0',

    [AllowNull()]
    [AllowEmptyString()]
    $EmailAddress = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $UserPrincipalName = $null,

    [string] $Model = 'Synthetic Laptop',

    [string] $Manufacturer = 'Fictional Devices',

    [string] $SerialNumber = "$DeviceName-SERIAL",

    [AllowNull()]
    [AllowEmptyString()]
    $UserDisplayName = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $DeviceEnrollmentType = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($LastSyncDateTime -lt $EnrolledDateTime) {
    throw 'LastSyncDateTime must be on or after EnrolledDateTime.'
}

$optionalStrings = @{
    UserId = $UserId
    EmailAddress = $EmailAddress
    UserPrincipalName = $UserPrincipalName
    UserDisplayName = $UserDisplayName
    DeviceEnrollmentType = $DeviceEnrollmentType
}
foreach ($propertyName in $optionalStrings.Keys) {
    $value = $optionalStrings[$propertyName]
    if ($null -ne $value -and $value -isnot [string]) {
        throw "$propertyName must be a string or null."
    }
}

$properties = [ordered]@{
    id = $Id.ToString()
    userId = $UserId
    deviceName = $DeviceName
    enrolledDateTime = $EnrolledDateTime.UtcDateTime.ToString('o')
    lastSyncDateTime = $LastSyncDateTime.UtcDateTime.ToString('o')
    operatingSystem = $OperatingSystem
    osVersion = $OSVersion
    emailAddress = $EmailAddress
    azureADDeviceId = $AzureAdDeviceId.ToString()
    userPrincipalName = $UserPrincipalName
    model = $Model
    manufacturer = $Manufacturer
    serialNumber = $SerialNumber
    userDisplayName = $UserDisplayName
}

if ($DeviceEnrollmentType) {
    $properties['deviceEnrollmentType'] = $DeviceEnrollmentType
}

$json = ConvertTo-Json -InputObject $properties -Depth 3

# Owner permits SDK model construction in non-PSU factory tools; JSON preserves nulls and read-only fields.
[Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice]::FromJsonString($json)
