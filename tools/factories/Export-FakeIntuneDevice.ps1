#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.DeviceManagement'; RequiredVersion = '2.41.2' }

<#
.SYNOPSIS
Exports synthetic managed-device models to a flat, 15-column CSV.
.DESCRIPTION
Replaces the destination CSV unless -Append is supplied. Defaults to
data/intune-devices.csv in this repository. Append adds rows without deduplication.
Dates are UTC ISO 8601 strings. Null and empty strings both become empty CSV cells.
Enrollment type is exported as text. An incompatible existing append header is
rejected by Export-Csv. The parent directory is created when needed. CSV does
not retain SDK types; the retrieval command restores source models and dates.
.PARAMETER InputObject
One or more Graph managed-device SDK models, supplied as an array or through the
pipeline. Non-model objects are rejected. At least one model is required.
.PARAMETER Path
Destination CSV path. Defaults to data/intune-devices.csv relative to this
repository. The path is interpreted literally.
.PARAMETER Append
Retains existing rows and appends new ones without deduplicating IDs. Creates a
missing file. Without this switch, the destination is replaced.
.INPUTS
Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice

Managed-device models to export.
.OUTPUTS
None

Writes the destination CSV without returning report rows.
.EXAMPLE
./tools/factories/New-FakeIntuneDevice.ps1 -DeviceName SYNTH-WIN-001 |
    ./tools/factories/Export-FakeIntuneDevice.ps1 -Path ./tools/output/example-devices.csv
Exports a generated device from the repository root, replacing the example file.
.EXAMPLE
$devices | ./tools/factories/Export-FakeIntuneDevice.ps1 -Path ./tools/output/example-devices.csv -Append
Appends supplied SDK models to the example file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [psobject[]] $InputObject,

    [ValidateNotNullOrEmpty()]
    [string] $Path = (Join-Path $PSScriptRoot '../../data/intune-devices.csv'),

    [switch] $Append
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $records = @()
}

process {
    foreach ($device in $InputObject) {
        if ($device -isnot [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]) {
            throw 'InputObject must contain Graph managed-device models.'
        }

        $records += [pscustomobject][ordered]@{
            id = $device.Id
            userId = $device.UserId
            deviceName = $device.DeviceName
            enrolledDateTime = if ($null -ne $device.EnrolledDateTime) {
                $device.EnrolledDateTime.ToUniversalTime().ToString('o')
            } else { $null }
            lastSyncDateTime = if ($null -ne $device.LastSyncDateTime) {
                $device.LastSyncDateTime.ToUniversalTime().ToString('o')
            } else { $null }
            operatingSystem = $device.OperatingSystem
            osVersion = $device.OSVersion
            emailAddress = $device.EmailAddress
            azureADDeviceId = $device.AzureAdDeviceId
            userPrincipalName = $device.UserPrincipalName
            model = $device.Model
            manufacturer = $device.Manufacturer
            serialNumber = $device.SerialNumber
            userDisplayName = $device.UserDisplayName
            deviceEnrollmentType = if ($null -ne $device.DeviceEnrollmentType) {
                [string] $device.DeviceEnrollmentType
            } else { $null }
        }
    }
}

end {
    if ($records.Count -eq 0) {
        throw 'Provide at least one managed-device model to export.'
    }

    $parentDirectory = Split-Path -Path $Path -Parent
    if ($parentDirectory) {
        New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
    }

    $records | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8 -Append:$Append
}
