#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.DeviceManagement'; RequiredVersion = '2.41.2' }

<#
.SYNOPSIS
Creates a synthetic Intune managed-device object without connecting to Graph.
.DESCRIPTION
Requires Microsoft.Graph.DeviceManagement 2.41.2. Returns an SDK model without
writing files. Supply identifiers and timestamps for repeatable fixture data.
User association defaults to null. Construction uses the SDK JSON deserializer
to populate read-only fields and preserve null, empty, and whitespace user IDs.
.PARAMETER DeviceName
Required nonempty device name.
.PARAMETER Id
Intune managed-device record GUID. Defaults to a newly generated GUID.
.PARAMETER AzureAdDeviceId
Entra device GUID, distinct from Id. Defaults to a newly generated GUID.
.PARAMETER UserId
Associated user identifier as a string or null. Defaults to null.
.PARAMETER LastSyncDateTime
Last successful sync timestamp. Defaults to the current UTC time and must be
on or after EnrolledDateTime.
.PARAMETER EnrolledDateTime
Enrollment timestamp. Defaults to 30 days before LastSyncDateTime.
.PARAMETER OperatingSystem
Nonempty OS label. Defaults to Windows.
.PARAMETER OSVersion
Nonempty OS version. Defaults to 10.0.26100.0.
.PARAMETER EmailAddress
Associated email address as a string or null. Defaults to null.
.PARAMETER UserPrincipalName
Associated user principal name as a string or null. Defaults to null.
.PARAMETER Model
Hardware model text. Defaults to Synthetic Laptop.
.PARAMETER Manufacturer
Hardware manufacturer text. Defaults to Fictional Devices.
.PARAMETER SerialNumber
Serial number text. Defaults to the device name followed by -SERIAL.
.PARAMETER UserDisplayName
Associated user display name as a string or null. Defaults to null.
.PARAMETER DeviceEnrollmentType
SDK enrollment type text. Null or empty values omit the property from construction.
No enrollment mode is inferred from device or user details.
.INPUTS
None

Pipeline input is not accepted.
.OUTPUTS
Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice

One SDK managed-device model. No files are written.
.EXAMPLE
./tools/factories/New-FakeIntuneDevice.ps1 -DeviceName SYNTH-WIN-001
Creates a device from the repository root using generated identifiers and default dates.
.EXAMPLE
./tools/factories/New-FakeIntuneDevice.ps1 -DeviceName SYNTH-WIN-001 |
    ./tools/factories/Export-FakeIntuneDevice.ps1 -Path ./tools/output/example-devices.csv
Creates a device and exports it to a separate example file from the repository root.
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
