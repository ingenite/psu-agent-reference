function ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport {
    <#
    .SYNOPSIS
    Reports Windows Intune devices with a missing primary-user association.
    .DESCRIPTION
    Transforms supplied source objects without retrieval or source mutation.
    Matches operatingSystem equal to Windows (case-insensitive) and userId null,
    empty, or whitespace. Display name, email, and UPN do not affect selection.
    Missing association is descriptive; intentionally userless devices may match.
    Emits rows in source order without deduplication. Empty or null input emits
    no rows. Enrollment type is text; other selected source values are preserved.
    .PARAMETER InputObject
    Managed-device source objects with the properties returned by Get-ParIntuneDevice.
    Accepts an array or pipeline input. Null objects are ignored.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    IntuneDeviceId, AzureAdDeviceId, DeviceName, SerialNumber, Manufacturer, Model,
    OperatingSystem, OSVersion, DeviceEnrollmentType, EnrolledDateTime,
    LastSyncDateTime, and UserId.
    .EXAMPLE
    $devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport
    .EXAMPLE
    ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices
    .LINK
    ../../../docs/reports/intune-devices-without-primary-user.md
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $InputObject
    )

    process {
        foreach ($device in $InputObject) {
            if ($null -eq $device) {
                continue
            }

            if ($device.OperatingSystem -eq 'Windows' -and ([string] $device.UserId).Trim() -eq '') {
                [pscustomobject][ordered]@{
                    IntuneDeviceId = $device.Id
                    AzureAdDeviceId = $device.AzureAdDeviceId
                    DeviceName = $device.DeviceName
                    SerialNumber = $device.SerialNumber
                    Manufacturer = $device.Manufacturer
                    Model = $device.Model
                    OperatingSystem = $device.OperatingSystem
                    OSVersion = $device.OSVersion
                    DeviceEnrollmentType = [string] $device.DeviceEnrollmentType
                    EnrolledDateTime = $device.EnrolledDateTime
                    LastSyncDateTime = $device.LastSyncDateTime
                    UserId = $device.UserId
                }
            }
        }
    }
}
